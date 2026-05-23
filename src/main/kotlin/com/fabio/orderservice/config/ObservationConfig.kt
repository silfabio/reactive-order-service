package com.fabio.orderservice.config

import io.micrometer.observation.ObservationPredicate
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.http.server.reactive.observation.ServerRequestObservationContext

/**
 * Configuration for Micrometer Observation behavior.
 * (proxyBeanMethods = false) is a performance optimization for configuration classes
 * that do not have @Bean methods calling each other.
 */
@Configuration(proxyBeanMethods = false)
class ObservationConfig {
    companion object {
        private const val ACTUATOR_PATH_PREFIX = "/actuator"
    }

    @Bean
    fun noActuatorObservations(): ObservationPredicate {
        return ObservationPredicate { _, context ->
            when (context) {
                is ServerRequestObservationContext -> !context.carrier.path.value().startsWith(ACTUATOR_PATH_PREFIX)
                else -> true
            }
        }
    }
}
