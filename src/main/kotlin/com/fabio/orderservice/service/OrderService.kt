package com.fabio.orderservice.service

import com.fabio.orderservice.domain.Order
import com.fabio.orderservice.domain.OrderRepository
import io.micrometer.observation.Observation
import io.micrometer.observation.ObservationRegistry
import org.slf4j.LoggerFactory
import org.springframework.cloud.stream.function.StreamBridge
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono
import java.util.UUID

@Service
class OrderService(
    private val orderRepository: OrderRepository,
    private val streamBridge: StreamBridge,
    private val observationRegistry: ObservationRegistry,
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    fun createOrder(order: Order): Mono<Order> {
        val orderWithId = order.copy(_id = UUID.randomUUID())

        return Mono.defer {
            val observation =
                Observation
                    .createNotStarted("orders.created", observationRegistry)
                    .lowCardinalityKeyValue("itemName", order.itemName) // Add a tag for the item name
                    .start()

            orderRepository
                .save(orderWithId)
                .doOnNext { savedOrder ->
                    logger.info("Publishing event for created order: {}", savedOrder.id)
                    streamBridge.send("publishOrder-out-0", savedOrder)
                }.doOnSuccess { observation.stop() }
                .doOnError { throwable ->
                    observation.error(throwable)
                    observation.stop()
                }.doOnCancel { observation.stop() }
        }
    }

    fun findById(id: UUID): Mono<Order> = orderRepository.findById(id)
}
