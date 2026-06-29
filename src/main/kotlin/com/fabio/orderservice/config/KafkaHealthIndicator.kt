package com.fabio.orderservice.config

import jakarta.annotation.PreDestroy
import org.apache.kafka.clients.admin.AdminClient
import org.apache.kafka.clients.admin.AdminClientConfig
import org.springframework.beans.factory.annotation.Value
import org.springframework.boot.actuate.health.Health
import org.springframework.boot.actuate.health.ReactiveHealthIndicator
import org.springframework.stereotype.Component
import reactor.core.publisher.Mono
import reactor.core.scheduler.Schedulers
import java.util.concurrent.TimeUnit

@Component("kafka")
class KafkaHealthIndicator(
    @Value("\${spring.kafka.bootstrap-servers}") bootstrapServers: String,
) : ReactiveHealthIndicator {
    private val adminClient: AdminClient =
        AdminClient.create(
            mapOf(
                AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG to bootstrapServers,
                AdminClientConfig.REQUEST_TIMEOUT_MS_CONFIG to 3_000,
                AdminClientConfig.DEFAULT_API_TIMEOUT_MS_CONFIG to 3_000,
            ),
        )

    override fun health(): Mono<Health> =
        Mono
            .fromCallable {
                val cluster = adminClient.describeCluster()
                val controller = cluster.controller().get(3, TimeUnit.SECONDS)
                val nodeCount = cluster.nodes().get(3, TimeUnit.SECONDS).size
                Health
                    .up()
                    .withDetail("brokerId", controller.idString())
                    .withDetail("nodeCount", nodeCount)
                    .build()
            }.onErrorResume { ex ->
                Mono.just(Health.down(ex).build())
            }.subscribeOn(Schedulers.boundedElastic())

    @PreDestroy
    fun destroy() = adminClient.close()
}
