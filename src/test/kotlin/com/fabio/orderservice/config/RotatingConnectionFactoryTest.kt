package com.fabio.orderservice.config

import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import io.r2dbc.spi.Connection
import io.r2dbc.spi.ConnectionFactory
import io.r2dbc.spi.ConnectionFactoryMetadata
import org.junit.jupiter.api.Test
import reactor.core.publisher.Mono
import reactor.test.StepVerifier

class RotatingConnectionFactoryTest {
    @Test
    fun `delegates to the initial connection factory until rotated`() {
        val initialConnection = mockk<Connection>()
        val rotatedConnection = mockk<Connection>()
        val initialFactory = mockk<ConnectionFactory>()
        val rotatedFactory = mockk<ConnectionFactory>()
        every { initialFactory.create() } returns Mono.just(initialConnection)
        every { rotatedFactory.create() } returns Mono.just(rotatedConnection)

        val factory = RotatingConnectionFactory(initialFactory)

        StepVerifier.create(factory.create()).expectNext(initialConnection).verifyComplete()

        factory.rotate(rotatedFactory)

        StepVerifier.create(factory.create()).expectNext(rotatedConnection).verifyComplete()
    }

    @Test
    fun `delegates metadata to the current connection factory`() {
        val initialMetadata = mockk<ConnectionFactoryMetadata>()
        val rotatedMetadata = mockk<ConnectionFactoryMetadata>()
        val initialFactory = mockk<ConnectionFactory>()
        val rotatedFactory = mockk<ConnectionFactory>()
        every { initialFactory.metadata } returns initialMetadata
        every { rotatedFactory.metadata } returns rotatedMetadata

        val factory = RotatingConnectionFactory(initialFactory)

        factory.metadata shouldBe initialMetadata

        factory.rotate(rotatedFactory)

        factory.metadata shouldBe rotatedMetadata
    }
}
