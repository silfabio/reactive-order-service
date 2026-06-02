package com.fabio.orderservice.service

import com.fabio.orderservice.domain.Order
import com.fabio.orderservice.domain.OrderRepository
import com.fabio.orderservice.domain.OrderStatus
import io.github.resilience4j.retry.RetryConfig
import io.github.resilience4j.retry.RetryRegistry
import io.kotest.matchers.shouldBe
import io.micrometer.core.instrument.simple.SimpleMeterRegistry
import io.mockk.every
import io.mockk.impl.annotations.InjectMockKs
import io.mockk.impl.annotations.MockK
import io.mockk.junit5.MockKExtension
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.springframework.cloud.stream.function.StreamBridge
import reactor.core.publisher.Mono
import reactor.test.StepVerifier
import java.io.IOException
import java.time.Duration
import java.util.UUID

@ExtendWith(MockKExtension::class)
class OrderServiceTest {
    @MockK
    lateinit var orderRepository: OrderRepository

    @MockK(relaxed = true)
    lateinit var streamBridge: StreamBridge

    private val meterRegistry = SimpleMeterRegistry()

    private val retryRegistry =
        RetryRegistry.of(
            RetryConfig.custom<Any>()
                .maxAttempts(3)
                .waitDuration(Duration.ofMillis(1))
                .build(),
        )

    @InjectMockKs
    lateinit var orderService: OrderService

    @BeforeEach
    fun setup() {
        orderService = OrderService(orderRepository, streamBridge, meterRegistry, retryRegistry)
    }

    @Test
    fun `should create order successfully and record timer`() {
        // GIVEN
        val orderToCreate = Order(itemName = "ROG Ally X", amount = 1)
        val savedOrder = orderToCreate.copy(_id = UUID.randomUUID(), status = OrderStatus.PENDING)

        every { orderRepository.save(any()) } returns Mono.just(savedOrder)

        // WHEN
        val result = orderService.createOrder(orderToCreate)

        // THEN
        StepVerifier.create(result).expectNext(savedOrder).verifyComplete()
        meterRegistry.get("orders.creation.duration").timer().count() shouldBe 1
    }

    @Test
    fun `should record timer on error during order creation`() {
        // GIVEN
        val orderToCreate = Order(itemName = "Faulty Item", amount = 1)
        val testException = IOException("Database connection failed")

        every { orderRepository.save(any()) } returns Mono.error(testException)

        // WHEN
        val result = orderService.createOrder(orderToCreate)

        // THEN
        StepVerifier.create(result).expectError(IOException::class.java).verify()
        meterRegistry.get("orders.creation.duration").timer().count() shouldBe 1
    }

    @Test
    fun `should record timer on cancellation during order creation`() {
        // GIVEN
        val orderToCreate = Order(itemName = "Cancelled Item", amount = 1)
        every { orderRepository.save(any()) } returns Mono.never()

        // WHEN
        val result = orderService.createOrder(orderToCreate)

        // THEN
        StepVerifier.create(result).thenCancel().verify()
        meterRegistry.get("orders.creation.duration").timer().count() shouldBe 1
    }

    @Test
    fun `should find order by id successfully`() {
        // GIVEN
        val existingOrder = Order(_id = UUID.randomUUID(), itemName = "Existing Item", amount = 5, status = OrderStatus.COMPLETED)
        every { orderRepository.findById(existingOrder.id!!) } returns Mono.just(existingOrder)

        // WHEN
        val result = orderService.findById(existingOrder.id!!)

        // THEN
        StepVerifier.create(result).expectNext(existingOrder).verifyComplete()
    }

    @Test
    fun `should return empty mono if order not found`() {
        // GIVEN
        val nonExistentId = UUID.randomUUID()
        every { orderRepository.findById(nonExistentId) } returns Mono.empty()

        // WHEN
        val result = orderService.findById(nonExistentId)

        // THEN
        StepVerifier.create(result).expectNextCount(0).verifyComplete()
    }

    @Test
    fun `should succeed on second attempt after transient repository failure`() {
        // GIVEN
        val orderToCreate = Order(itemName = "ROG Ally X", amount = 1)
        val savedOrder = orderToCreate.copy(_id = UUID.randomUUID(), status = OrderStatus.PENDING)

        every { orderRepository.save(any()) } returnsMany
            listOf(
                Mono.error(IOException("Transient failure")),
                Mono.just(savedOrder),
            )

        // WHEN
        val result = orderService.createOrder(orderToCreate)

        // THEN
        StepVerifier.create(result).expectNext(savedOrder).verifyComplete()
        meterRegistry.get("orders.creation.duration").timer().count() shouldBe 1
    }

    @Test
    fun `should propagate error after exhausting all retry attempts`() {
        // GIVEN
        val orderToCreate = Order(itemName = "Persistent Failure Item", amount = 1)
        val testException = IOException("Persistent failure")

        every { orderRepository.save(any()) } returns Mono.error(testException)

        // WHEN
        val result = orderService.createOrder(orderToCreate)

        // THEN
        StepVerifier.create(result).expectError(IOException::class.java).verify()
        meterRegistry.get("orders.creation.duration").timer().count() shouldBe 1
    }
}
