package com.fabio.orderservice.config

import io.r2dbc.postgresql.PostgresqlConnectionFactoryProvider.SSL_CERT
import io.r2dbc.postgresql.PostgresqlConnectionFactoryProvider.SSL_KEY
import io.r2dbc.postgresql.PostgresqlConnectionFactoryProvider.SSL_MODE
import io.r2dbc.postgresql.PostgresqlConnectionFactoryProvider.SSL_ROOT_CERT
import io.r2dbc.postgresql.client.SSLMode
import io.r2dbc.spi.ConnectionFactories
import io.r2dbc.spi.ConnectionFactory
import io.r2dbc.spi.ConnectionFactoryOptions
import org.springframework.beans.factory.annotation.Value
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

/**
 * Builds the R2DBC `ConnectionFactory` for mTLS connections to Postgres, using the
 * short-lived client certificate issued by [VaultPkiCertificateManager]. Connects as
 * the `order_service` role (see `infra/postgres/pg_ident.conf`), authenticated by
 * presenting the certificate — no password.
 */
@Configuration(proxyBeanMethods = false)
@EnableConfigurationProperties(VaultPkiProperties::class)
@ConditionalOnProperty(prefix = "vault.pki", name = ["enabled"], matchIfMissing = true)
class R2dbcConnectionFactoryConfig {
    @Bean
    fun connectionFactory(
        @Value("\${spring.r2dbc.url}") url: String,
        certificateManager: VaultPkiCertificateManager,
    ): ConnectionFactory {
        val rotatingFactory = RotatingConnectionFactory(buildConnectionFactory(url, certificateManager))
        certificateManager.rotations()
            .skip(1)
            .subscribe { rotatingFactory.rotate(buildConnectionFactory(url, certificateManager)) }
        return rotatingFactory
    }

    private fun buildConnectionFactory(
        url: String,
        certificateManager: VaultPkiCertificateManager,
    ): ConnectionFactory {
        val options =
            ConnectionFactoryOptions.parse(url).mutate()
                .option(ConnectionFactoryOptions.SSL, true)
                .option(ConnectionFactoryOptions.USER, CLIENT_CERT_DATABASE_USER)
                .option(SSL_MODE, SSLMode.VERIFY_FULL)
                .option(SSL_CERT, certificateManager.certificatePath.toString())
                .option(SSL_KEY, certificateManager.privateKeyPath.toString())
                .option(SSL_ROOT_CERT, certificateManager.caChainPath.toString())
                .build()
        return ConnectionFactories.get(options)
    }

    private companion object {
        const val CLIENT_CERT_DATABASE_USER = "order_service"
    }
}
