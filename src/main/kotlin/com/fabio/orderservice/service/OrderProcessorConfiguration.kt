package com.fabio.orderservice.service

import com.fabio.orderservice.domain.Order
import com.fabio.orderservice.domain.OrderRepository
import com.fabio.orderservice.domain.OrderStatus
import org.slf4j.LoggerFactory
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.Duration
import java.util.function.Function

@Configuration
class OrderProcessorConfiguration(private val repository: OrderRepository) {

    private val logger = LoggerFactory.getLogger(javaClass)

    @Bean
    fun processOrder(): Function<Flux<Order>, Mono<Void>> {
        return Function { inputFlux ->
            inputFlux
                .flatMap { order ->
                    logger.info("Received order to process: {}", order.id)

                    // Create an immutable copy with the updated status
                    val processedOrder = order.copy(status = OrderStatus.PROCESSING)

                    // Simulate processing time (e.g., calling another service)
                    Mono.just(processedOrder)
                        .delayElement(Duration.ofSeconds(2))
                        .flatMap { updatedOrder ->
                            repository.save(updatedOrder)
                        }
                        .doOnNext { savedOrder ->
                            logger.info("✅ Successfully processed and saved order: {}", savedOrder.id)
                        }
                }
                .then() // return Mono<Void> to indicate the stream is handled
        }
    }
}
