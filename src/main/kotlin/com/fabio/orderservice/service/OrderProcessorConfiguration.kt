package com.fabio.orderservice.service

import com.fabio.orderservice.domain.Order
import com.fabio.orderservice.domain.OrderRepository
import com.fabio.orderservice.domain.OrderStatus
import io.github.resilience4j.reactor.retry.RetryOperator
import io.github.resilience4j.retry.RetryRegistry
import org.slf4j.LoggerFactory
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import reactor.core.publisher.Mono
import java.time.Duration
import java.util.function.Consumer

@Configuration
class OrderProcessorConfiguration(
    private val repository: OrderRepository,
    private val retryRegistry: RetryRegistry,
) {
    private val logger = LoggerFactory.getLogger(javaClass)
    private val retry = retryRegistry.retry("orderRepository")

    /**
     * Defines a Spring Cloud Stream consumer function.
     * - It is a `Consumer<Order>`, meaning it accepts one `Order` at a time.
     * - Spring Cloud Stream automatically handles the `Flux` and subscribes to it.
     * - The return type is a `(Order) -> Unit` lambda, which is a side-effecting function.
     */
    @Bean
    fun processOrder(): Consumer<Order> =
        Consumer { order ->
            if (order.status == OrderStatus.PENDING) {
                logger.info("Received order to process: {}", order.id)

                val processedOrder = order.copy(status = OrderStatus.PROCESSING)

                Mono
                    .just(processedOrder)
                    .delayElement(Duration.ofSeconds(2))
                    .flatMap { updatedOrder ->
                        Mono.defer { repository.save(updatedOrder) }
                            .transformDeferred(RetryOperator.of(retry))
                    }.doOnNext { savedOrder ->
                        logger.info("✅ Successfully processed and saved order: {}", savedOrder.id)
                    }.doOnError { e ->
                        logger.error("❌ Failed to process order: ${order.id}", e)
                    }.subscribe()
            }
        }
}
