package com.fabio.orderservice.config

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.annotation.JsonProperty
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.http.MediaType
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.client.WebClient
import org.springframework.web.reactive.function.client.bodyToMono
import reactor.core.publisher.Mono
import java.time.Duration
import java.time.Instant

/** A short-lived mTLS client certificate issued by Vault's PKI secrets engine. */
data class PkiCertificate(
    val certificatePem: String,
    val privateKeyPem: String,
    val caChainPem: String,
    val expiresAt: Instant,
    val ttl: Duration,
)

@JsonIgnoreProperties(ignoreUnknown = true)
private data class VaultLoginResponse(
    @JsonProperty("auth") val auth: Auth,
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    data class Auth(
        @JsonProperty("client_token") val clientToken: String,
    )
}

@JsonIgnoreProperties(ignoreUnknown = true)
private data class VaultIssueResponse(
    @JsonProperty("data") val data: Data,
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    data class Data(
        @JsonProperty("certificate") val certificate: String,
        @JsonProperty("private_key") val privateKey: String,
        @JsonProperty("issuing_ca") val issuingCa: String,
        @JsonProperty("ca_chain") val caChain: List<String> = emptyList(),
        @JsonProperty("expiration") val expiration: Long,
    )
}

/**
 * Authenticates against Vault via AppRole and issues short-lived mTLS client
 * certificates from the `pki-int` mount provisioned by
 * `infra/terraform/modules/vault-pki`.
 */
@Component
@ConditionalOnProperty(prefix = "vault.pki", name = ["enabled"], matchIfMissing = true)
class VaultPkiClient(
    private val properties: VaultPkiProperties,
    webClientBuilder: WebClient.Builder,
) {
    private val webClient = webClientBuilder.baseUrl(properties.address).build()

    /** Logs in via AppRole and issues a fresh client certificate. */
    fun issueCertificate(): Mono<PkiCertificate> = login().flatMap(::issue)

    private fun login(): Mono<String> {
        val requestBody =
            mapOf(
                "role_id" to properties.appRoleId,
                "secret_id" to properties.appRoleSecretId,
            )
        return webClient.post()
            .uri("/v1/auth/approle/login")
            .contentType(MediaType.APPLICATION_JSON)
            .bodyValue(requestBody)
            .retrieve()
            .bodyToMono<VaultLoginResponse>()
            .map { it.auth.clientToken }
    }

    private fun issue(clientToken: String): Mono<PkiCertificate> {
        // pkcs8: Vault's default PKCS#1 ("traditional") RSA key encoding isn't
        // parseable by Netty's SslContextBuilder.keyManager, which requires PKCS#8.
        val requestBody =
            mapOf(
                "common_name" to properties.commonName,
                "private_key_format" to "pkcs8",
            )
        return webClient.post()
            .uri("/v1/{mount}/issue/{role}", properties.pkiMountPath, properties.clientCertRole)
            .header("X-Vault-Token", clientToken)
            .contentType(MediaType.APPLICATION_JSON)
            .bodyValue(requestBody)
            .retrieve()
            .bodyToMono<VaultIssueResponse>()
            .map { it.toPkiCertificate() }
    }

    private fun VaultIssueResponse.toPkiCertificate(): PkiCertificate {
        val caChain = data.caChain.ifEmpty { listOf(data.issuingCa) }
        val expiresAt = Instant.ofEpochSecond(data.expiration)
        return PkiCertificate(
            certificatePem = data.certificate,
            privateKeyPem = data.privateKey,
            caChainPem = caChain.joinToString(separator = "\n"),
            expiresAt = expiresAt,
            // Vault's PKI issue endpoint returns lease_duration=0 (certs aren't leased
            // the renewable way), so derive the renewal interval from the cert's
            // actual validity period instead — otherwise renewalDelay() computes a
            // ~zero delay and the cert manager renews in a tight loop.
            ttl = Duration.between(Instant.now(), expiresAt),
        )
    }
}
