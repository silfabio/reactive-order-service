package com.fabio.orderservice.config

import jakarta.annotation.PostConstruct
import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.stereotype.Component
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import reactor.core.publisher.Sinks
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.attribute.PosixFilePermissions
import java.time.Duration

/**
 * Fetches the Order Service's mTLS client certificate from Vault PKI at startup,
 * writes it to fixed file paths for r2dbc-postgresql/Flyway to consume, and
 * renews it before it expires.
 *
 * Renewals overwrite the same files in place and emit on [rotations] so that
 * [R2dbcConnectionFactoryConfig] can rebuild the R2DBC `ConnectionFactory` with the
 * refreshed key material — r2dbc-postgresql reads certificate/key files once when
 * the `ConnectionFactory` is built, not per connection.
 */
@Component
@ConditionalOnProperty(prefix = "vault.pki", name = ["enabled"], matchIfMissing = true)
class VaultPkiCertificateManager(
    private val properties: VaultPkiProperties,
    private val vaultPkiClient: VaultPkiClient,
) {
    private val logger = LoggerFactory.getLogger(VaultPkiCertificateManager::class.java)

    private val certDirectory: Path = Path.of(properties.certDirectory)

    val certificatePath: Path = certDirectory.resolve("client.crt")
    val privateKeyPath: Path = certDirectory.resolve("client.key")
    val caChainPath: Path = certDirectory.resolve("ca-chain.crt")

    private val rotations = Sinks.many().replay().latest<PkiCertificate>()

    /** Emits the initial certificate, then each renewed certificate as it's issued. */
    fun rotations(): Flux<PkiCertificate> = rotations.asFlux()

    @PostConstruct
    fun initialize() {
        val certificate =
            vaultPkiClient.issueCertificate().block(INITIAL_FETCH_TIMEOUT)
                ?: error("Timed out issuing initial Vault PKI certificate from ${properties.address}")
        writeToDisk(certificate)
        rotations.tryEmitNext(certificate)
        logger.info("Issued Vault PKI client certificate for '{}', expires at {}", properties.commonName, certificate.expiresAt)
        scheduleRenewal(renewalDelay(certificate.ttl))
    }

    private fun scheduleRenewal(delay: Duration) {
        Mono.delay(delay)
            .flatMap { vaultPkiClient.issueCertificate() }
            .subscribe(
                { certificate ->
                    writeToDisk(certificate)
                    rotations.tryEmitNext(certificate)
                    logger.info("Renewed Vault PKI client certificate, expires at {}", certificate.expiresAt)
                    scheduleRenewal(renewalDelay(certificate.ttl))
                },
                { error ->
                    logger.error("Failed to renew Vault PKI client certificate, retrying in {}", RETRY_DELAY, error)
                    scheduleRenewal(RETRY_DELAY)
                },
            )
    }

    private fun renewalDelay(ttl: Duration): Duration = Duration.ofMillis((ttl.toMillis() * properties.renewalThreshold).toLong())

    private fun writeToDisk(certificate: PkiCertificate) {
        Files.createDirectories(certDirectory)
        writeFile(certificatePath, certificate.certificatePem, READ_ONLY_PERMISSIONS)
        writeFile(privateKeyPath, certificate.privateKeyPem, OWNER_ONLY_PERMISSIONS)
        writeFile(caChainPath, certificate.caChainPem, READ_ONLY_PERMISSIONS)
    }

    private fun writeFile(
        path: Path,
        content: String,
        permissions: String,
    ) {
        Files.writeString(path, content)
        try {
            Files.setPosixFilePermissions(path, PosixFilePermissions.fromString(permissions))
        } catch (_: UnsupportedOperationException) {
            // Non-POSIX filesystem (e.g. Windows) — best effort.
        }
    }

    private companion object {
        val INITIAL_FETCH_TIMEOUT: Duration = Duration.ofSeconds(30)
        val RETRY_DELAY: Duration = Duration.ofSeconds(30)
        const val READ_ONLY_PERMISSIONS = "rw-r--r--"
        const val OWNER_ONLY_PERMISSIONS = "rw-------"
    }
}
