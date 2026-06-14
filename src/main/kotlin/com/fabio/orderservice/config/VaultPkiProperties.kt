package com.fabio.orderservice.config

import org.springframework.boot.context.properties.ConfigurationProperties

/**
 * Configuration for fetching short-lived mTLS client certificates from Vault's PKI
 * secrets engine (see `infra/terraform/modules/vault-pki`).
 */
@ConfigurationProperties(prefix = "vault.pki")
data class VaultPkiProperties(
    val enabled: Boolean = true,
    val address: String = "http://localhost:8200",
    val appRoleId: String = "",
    val appRoleSecretId: String = "",
    val pkiMountPath: String = "pki-int",
    val clientCertRole: String = "order-service-client",
    val commonName: String = "order-service.client",
    val certDirectory: String = "${System.getProperty("java.io.tmpdir")}/order-service-pki",
    /** Fraction of the issued certificate's TTL to wait before renewing it. */
    val renewalThreshold: Double = 0.5,
)
