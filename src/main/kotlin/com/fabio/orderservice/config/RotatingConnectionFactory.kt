package com.fabio.orderservice.config

import io.r2dbc.spi.Connection
import io.r2dbc.spi.ConnectionFactory
import io.r2dbc.spi.ConnectionFactoryMetadata
import org.reactivestreams.Publisher
import java.util.concurrent.atomic.AtomicReference

/**
 * A [ConnectionFactory] that delegates to a swappable underlying instance, allowing
 * [VaultPkiCertificateManager] to rebuild the delegate with renewed mTLS certificates
 * without requiring this bean (and its dependents) to be recreated.
 */
class RotatingConnectionFactory(initial: ConnectionFactory) : ConnectionFactory {
    private val delegate = AtomicReference(initial)

    fun rotate(factory: ConnectionFactory) {
        delegate.set(factory)
    }

    override fun create(): Publisher<out Connection> = delegate.get().create()

    override fun getMetadata(): ConnectionFactoryMetadata = delegate.get().metadata
}
