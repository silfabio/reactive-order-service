/*
 * Copyright 2026-2026 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.fabio.orderservice.service

import com.fabio.orderservice.domain.Order
import com.fabio.orderservice.domain.OrderRepository
import com.fabio.orderservice.domain.OrderStatus
import com.ninjasquad.springmockk.MockkBean
import io.kotest.matchers.shouldBe
import io.mockk.confirmVerified
import io.mockk.every
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.cloud.stream.binder.test.InputDestination
import org.springframework.cloud.stream.binder.test.TestChannelBinderConfiguration
import org.springframework.context.annotation.Import
import org.springframework.messaging.support.MessageBuilder
import reactor.core.publisher.Mono
import java.util.UUID

// Define the necessary bindings directly in the test properties.
// This makes the test self-contained and independent of the main application.yml.
@SpringBootTest(
    properties = [
        "spring.autoconfigure.exclude=" +
            "org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration," +
            "org.springframework.boot.autoconfigure.r2dbc.R2dbcAutoConfiguration",
        "spring.cloud.stream.bindings.processOrder-in-0.destination=order-events",
    ],
)
@Import(TestChannelBinderConfiguration::class)
class OrderProcessorTest {
    @Autowired
    private lateinit var inputDestination: InputDestination

    @MockkBean
    private lateinit var orderRepository: OrderRepository

    @Test
    fun `should process a new order and update its status to PROCESSING`() {
        // GIVEN
        val inputOrder =
            Order(
                _id = UUID.randomUUID(),
                itemName = "ROG Ally X",
                amount = 1,
                status = OrderStatus.PENDING,
            )

        // Create a slot to capture the Order object passed to the repository
        val orderSlot = slot<Order>()

        // When repository.save is called, just return the same object.
        every { orderRepository.save(any()) } answers { Mono.just(firstArg()) }

        // WHEN
        // Send the message to the DESTINATION name ("order-events")
        inputDestination.send(MessageBuilder.withPayload(inputOrder).build(), "order-events")

        // THEN
        // This waits for the async call and populates the slot in one step.
        verify(timeout = 5000, exactly = 1) {
            orderRepository.save(capture(orderSlot))
        }

        // After the verify block completes, the slot is guaranteed to be populated.
        // Now we can safely access the captured value.
        val capturedOrder = orderSlot.captured
        capturedOrder.id shouldBe inputOrder.id
        capturedOrder.itemName shouldBe inputOrder.itemName
        capturedOrder.status shouldBe OrderStatus.PROCESSING // This is the crucial assertion

        // As a best practice, confirm that no other unexpected calls were made to the mock.
        confirmVerified(orderRepository)
    }
}
