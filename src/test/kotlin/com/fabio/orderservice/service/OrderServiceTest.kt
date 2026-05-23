package com.fabio.orderservice.service

import com.fabio.orderservice.domain.Order
import com.fabio.orderservice.domain.OrderRepository
import com.fabio.orderservice.domain.OrderStatus
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.mockk.every
import io.mockk.impl.annotations.InjectMockKs
import io.mockk.impl.annotations.MockK
import io.mockk.junit5.MockKExtension
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.springframework.cloud.stream.function.StreamBridge
import reactor.core.publisher.Mono
import reactor.test.StepVerifier
import java.util.UUID

@ExtendWith(MockKExtension::class)
class OrderServiceTest {
    @MockK
    lateinit var orderRepository: OrderRepository

    @MockK(relaxed = true)
    lateinit var streamBridge: StreamBridge

    @InjectMockKs
    lateinit var orderService: OrderService

    @Test
    fun `should create order successfully`() {
        // GIVEN
        val orderToCreate = Order(itemName = "ROG Ally X", amount = 1)
        val savedOrder = orderToCreate.copy(_id = UUID.randomUUID(), status = OrderStatus.PENDING)

        val repositoryOrderSlot = slot<Order>()
        val streamBridgeOrderSlot = slot<Order>()

        every { orderRepository.save(capture(repositoryOrderSlot)) } returns Mono.just(savedOrder)
        every { streamBridge.send(any<String>(), capture(streamBridgeOrderSlot)) } returns true

        // WHEN
        val result = orderService.createOrder(orderToCreate)

        // THEN
        StepVerifier.create(result)
            .expectNext(savedOrder)
            .verifyComplete()

        // Verify repository interaction
        verify(exactly = 1) { orderRepository.save(any<Order>()) }
        verify(exactly = 1) { streamBridge.send("publishOrder-out-0", any<Order>()) }

        // Assert on the captured values
        val capturedRepoOrder = repositoryOrderSlot.captured
        capturedRepoOrder.id shouldNotBe null
        capturedRepoOrder.itemName shouldBe orderToCreate.itemName
        capturedRepoOrder.amount shouldBe orderToCreate.amount
        capturedRepoOrder.status shouldBe OrderStatus.PENDING

        val capturedStreamOrder = streamBridgeOrderSlot.captured
        capturedStreamOrder shouldBe savedOrder
    }

    @Test
    fun `should find order by id successfully`() {
        // GIVEN
        val existingOrder = Order(_id = UUID.randomUUID(), itemName = "Existing Item", amount = 5, status = OrderStatus.COMPLETED)
        every { orderRepository.findById(existingOrder.id!!) } returns Mono.just(existingOrder)

        // WHEN
        val result = orderService.findById(existingOrder.id!!)

        // THEN
        StepVerifier.create(result)
            .expectNext(existingOrder)
            .verifyComplete()

        verify(exactly = 1) { orderRepository.findById(existingOrder.id!!) }
    }

    @Test
    fun `should return empty mono if order not found`() {
        // GIVEN
        val nonExistentId = UUID.randomUUID()
        every { orderRepository.findById(nonExistentId) } returns Mono.empty()

        // WHEN
        val result = orderService.findById(nonExistentId)

        // THEN
        StepVerifier.create(result)
            .expectNextCount(0)
            .verifyComplete()

        verify(exactly = 1) { orderRepository.findById(nonExistentId) }
    }
}
