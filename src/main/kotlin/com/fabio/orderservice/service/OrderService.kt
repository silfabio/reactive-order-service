package com.fabio.orderservice.service

import com.fabio.orderservice.domain.Order
import com.fabio.orderservice.domain.OrderRepository
import io.micrometer.core.instrument.MeterRegistry
import io.micrometer.core.instrument.Timer
import org.slf4j.LoggerFactory
import org.springframework.cloud.stream.function.StreamBridge
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono
import java.util.UUID

@Service
class OrderService(
    private val orderRepository: OrderRepository,
    private val streamBridge: StreamBridge,
    private val meterRegistry: MeterRegistry,
) {
    private val logger = LoggerFactory.getLogger(javaClass)
    private val orderCreationTimer: Timer = meterRegistry.timer("orders.creation.duration")

    fun createOrder(order: Order): Mono<Order> {
        val orderWithId = order.copy(_id = UUID.randomUUID())
        val sample = Timer.start(meterRegistry)

        return orderRepository.save(orderWithId)
            .doOnSuccess {
                sample.stop(orderCreationTimer)
            }
            .doOnError {
                sample.stop(orderCreationTimer)
            }
            .doOnCancel {
                sample.stop(orderCreationTimer)
            }
            .doOnNext { savedOrder ->
                logger.info("Publishing event for created order: {}", savedOrder.id)
                streamBridge.send("publishOrder-out-0", savedOrder)
            }
    }

    fun findById(id: UUID): Mono<Order> = orderRepository.findById(id)
}
