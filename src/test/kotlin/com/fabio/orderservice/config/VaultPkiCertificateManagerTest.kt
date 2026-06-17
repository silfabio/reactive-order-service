package com.fabio.orderservice.config

import io.kotest.assertions.nondeterministic.eventually
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import reactor.core.publisher.Mono
import reactor.test.StepVerifier
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.attribute.PosixFilePermissions
import java.time.Duration
import java.time.Instant
import kotlin.time.Duration.Companion.seconds

class VaultPkiCertificateManagerTest {
    @Test
    fun `initialize fetches a certificate, writes it to disk with restrictive permissions, and emits it`(
        @TempDir tempDir: Path,
    ) {
        val vaultPkiClient = mockk<VaultPkiClient>()
        val properties = VaultPkiProperties(certDirectory = tempDir.toString())
        val initialCert = certificate(suffix = "1", ttl = Duration.ofHours(1))
        every { vaultPkiClient.issueCertificate() } returns Mono.just(initialCert)

        val manager = VaultPkiCertificateManager(properties, vaultPkiClient)
        manager.initialize()

        Files.readString(manager.certificatePath) shouldBe initialCert.certificatePem
        Files.readString(manager.privateKeyPath) shouldBe initialCert.privateKeyPem
        Files.readString(manager.caChainPath) shouldBe initialCert.caChainPem
        PosixFilePermissions.toString(Files.getPosixFilePermissions(manager.privateKeyPath)) shouldBe "rw-------"

        StepVerifier.create(manager.rotations())
            .assertNext { it shouldBe initialCert }
            .thenCancel()
            .verify()
    }

    @Test
    fun `renews the certificate before it expires and rotates the files in place`(
        @TempDir tempDir: Path,
    ) {
        val vaultPkiClient = mockk<VaultPkiClient>()
        val properties = VaultPkiProperties(certDirectory = tempDir.toString(), renewalThreshold = 0.5)
        val initialCert = certificate(suffix = "1", ttl = Duration.ofMillis(100))
        val renewedCert = certificate(suffix = "2", ttl = Duration.ofHours(1))
        every { vaultPkiClient.issueCertificate() } returnsMany
            listOf(Mono.just(initialCert), Mono.just(renewedCert))

        val manager = VaultPkiCertificateManager(properties, vaultPkiClient)
        manager.initialize()

        runBlocking {
            eventually(2.seconds) {
                Files.readString(manager.certificatePath) shouldBe renewedCert.certificatePem
            }
        }

        StepVerifier.create(manager.rotations())
            .assertNext { it shouldBe renewedCert }
            .thenCancel()
            .verify()
    }

    private fun certificate(
        suffix: String,
        ttl: Duration,
    ) = PkiCertificate(
        certificatePem = "CERT_$suffix",
        privateKeyPem = "KEY_$suffix",
        caChainPem = "CA_$suffix",
        expiresAt = Instant.now().plus(ttl),
        ttl = ttl,
    )
}
