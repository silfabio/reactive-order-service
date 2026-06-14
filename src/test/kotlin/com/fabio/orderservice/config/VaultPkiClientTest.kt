package com.fabio.orderservice.config

import io.kotest.matchers.comparables.shouldBeGreaterThan
import io.kotest.matchers.comparables.shouldBeLessThanOrEqualTo
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.web.reactive.function.client.ClientRequest
import org.springframework.web.reactive.function.client.ClientResponse
import org.springframework.web.reactive.function.client.ExchangeFunction
import org.springframework.web.reactive.function.client.WebClient
import reactor.core.publisher.Mono
import reactor.test.StepVerifier
import java.time.Duration
import java.time.Instant

class VaultPkiClientTest {
    private val properties =
        VaultPkiProperties(
            address = "http://vault.example:8200",
            appRoleId = "role-id",
            appRoleSecretId = "secret-id",
            pkiMountPath = "pki-int",
            clientCertRole = "order-service-client",
            commonName = "order-service.client",
        )

    @Test
    fun `logs in via AppRole then issues a client certificate`() {
        val expiresAt = Instant.now().plus(Duration.ofHours(24))
        val seenRequests = mutableListOf<ClientRequest>()
        val exchangeFunction =
            ExchangeFunction { request ->
                seenRequests.add(request)
                when (request.url().path) {
                    "/v1/auth/approle/login" -> loginResponse("vault-token-123")
                    "/v1/pki-int/issue/order-service-client" ->
                        issueResponse(
                            certificate = "CERT_PEM",
                            privateKey = "KEY_PEM",
                            caChain = listOf("INT_CA_PEM", "ROOT_CA_PEM"),
                            issuingCa = "INT_CA_PEM",
                            expiration = expiresAt.epochSecond,
                            // Vault's PKI issue endpoint returns lease_duration=0; the
                            // client must derive ttl from the expiration instead.
                            leaseDuration = 0L,
                        )
                    else -> error("Unexpected request: ${request.url()}")
                }
            }
        val client = VaultPkiClient(properties, WebClient.builder().exchangeFunction(exchangeFunction))

        StepVerifier.create(client.issueCertificate())
            .assertNext { cert ->
                cert.certificatePem shouldBe "CERT_PEM"
                cert.privateKeyPem shouldBe "KEY_PEM"
                cert.caChainPem shouldBe "INT_CA_PEM\nROOT_CA_PEM"
                cert.expiresAt shouldBe Instant.ofEpochSecond(expiresAt.epochSecond)
                cert.ttl shouldBeGreaterThan Duration.ofHours(23)
                cert.ttl shouldBeLessThanOrEqualTo Duration.ofHours(24)
            }
            .verifyComplete()

        seenRequests[0].url().toString() shouldBe "http://vault.example:8200/v1/auth/approle/login"
        seenRequests[1].url().toString() shouldBe "http://vault.example:8200/v1/pki-int/issue/order-service-client"
        seenRequests[1].headers().getFirst("X-Vault-Token") shouldBe "vault-token-123"
    }

    @Test
    fun `falls back to issuing_ca when ca_chain is empty`() {
        val exchangeFunction =
            ExchangeFunction { request ->
                when (request.url().path) {
                    "/v1/auth/approle/login" -> loginResponse("vault-token-123")
                    "/v1/pki-int/issue/order-service-client" ->
                        issueResponse(
                            certificate = "CERT_PEM",
                            privateKey = "KEY_PEM",
                            caChain = emptyList(),
                            issuingCa = "INT_CA_PEM",
                            expiration = 1_700_000_000L,
                            leaseDuration = 3_600L,
                        )
                    else -> error("Unexpected request: ${request.url()}")
                }
            }
        val client = VaultPkiClient(properties, WebClient.builder().exchangeFunction(exchangeFunction))

        StepVerifier.create(client.issueCertificate())
            .assertNext { cert -> cert.caChainPem shouldBe "INT_CA_PEM" }
            .verifyComplete()
    }

    private fun loginResponse(clientToken: String): Mono<ClientResponse> = jsonResponse("""{"auth":{"client_token":"$clientToken"}}""")

    private fun issueResponse(
        certificate: String,
        privateKey: String,
        caChain: List<String>,
        issuingCa: String,
        expiration: Long,
        leaseDuration: Long,
    ): Mono<ClientResponse> {
        val caChainJson = caChain.joinToString(separator = ",") { "\"$it\"" }
        return jsonResponse(
            """
            {
              "lease_duration": $leaseDuration,
              "data": {
                "certificate": "$certificate",
                "private_key": "$privateKey",
                "issuing_ca": "$issuingCa",
                "ca_chain": [$caChainJson],
                "expiration": $expiration
              }
            }
            """.trimIndent(),
        )
    }

    private fun jsonResponse(body: String): Mono<ClientResponse> =
        Mono.just(
            ClientResponse.create(HttpStatus.OK)
                .header("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                .body(body)
                .build(),
        )
}
