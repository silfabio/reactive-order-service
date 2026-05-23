package com.fabio.orderservice

import io.kotest.core.spec.style.DescribeSpec
import io.kotest.extensions.spring.SpringTestExtension
import io.r2dbc.spi.ConnectionFactories
import io.r2dbc.spi.ConnectionFactory
import io.r2dbc.spi.ConnectionFactoryOptions
import io.zonky.test.db.AutoConfigureEmbeddedDatabase
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import javax.sql.DataSource

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@AutoConfigureEmbeddedDatabase(
    type = AutoConfigureEmbeddedDatabase.DatabaseType.POSTGRES,
    provider = AutoConfigureEmbeddedDatabase.DatabaseProvider.ZONKY,
)
@Import(SpringTestSpec.R2dbcBridgeConfig::class)
abstract class SpringTestSpec : DescribeSpec() {
    init {
        extensions(SpringTestExtension())
    }

    @Configuration
    class R2dbcBridgeConfig {
        @Bean
        fun connectionFactory(context: org.springframework.context.ApplicationContext): ConnectionFactory {
            return object : ConnectionFactory {
                private fun getDelegate(): ConnectionFactory {
                    val dataSource = context.getBean(DataSource::class.java)
                    val jdbcUrl = dataSource.connection.use { it.metaData.url }

                    val dbName = jdbcUrl.substringAfterLast("/")
                    val port = jdbcUrl.substringAfter("localhost:").substringBefore("/").toInt()

                    return ConnectionFactories.get(
                        ConnectionFactoryOptions.builder()
                            .option(ConnectionFactoryOptions.DRIVER, "postgresql")
                            .option(ConnectionFactoryOptions.HOST, "localhost")
                            .option(ConnectionFactoryOptions.PORT, port)
                            .option(ConnectionFactoryOptions.DATABASE, dbName)
                            .option(ConnectionFactoryOptions.USER, "postgres")
                            .option(ConnectionFactoryOptions.PASSWORD, "")
                            .build(),
                    )
                }

                override fun create(): org.reactivestreams.Publisher<out io.r2dbc.spi.Connection> {
                    // This is the magic part: it recalculates the URL
                    // every time a connection is requested.
                    return getDelegate().create()
                }

                override fun getMetadata(): io.r2dbc.spi.ConnectionFactoryMetadata {
                    return getDelegate().metadata
                }
            }
        }
    }
}
