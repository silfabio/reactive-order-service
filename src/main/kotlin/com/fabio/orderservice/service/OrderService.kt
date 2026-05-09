package com.fabio.orderservice.service

import com.fabio.orderservice.domain.Order
import com.fabio.orderservice.domain.OrderRepository
import org.slf4j.LoggerFactory
import org.springframework.cloud.stream.function.StreamBridge
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono
import java.util.UUID

@Service
class OrderService(
    private val orderRepository: OrderRepository,
    private val streamBridge: StreamBridge
) {

    private val logger = LoggerFactory.getLogger(javaClass)

    fun createOrder(order: Order): Mono<Order> {
        // The 'order' object passed in has status=PENDING by default, so isNew() will be true.
        val orderWithId = order.copy(_id = UUID.randomUUID())

        return orderRepository.save(orderWithId)
            .doOnNext { savedOrder ->
                logger.info("Publishing event for created order: {}", savedOrder.id)
                // Send the saved order (with its ID) to the message broker.
                streamBridge.send("publishOrder-out-0", savedOrder)
            }
    }

    fun findById(id: UUID): Mono<Order> {
        return orderRepository.findById(id)
    }
}
