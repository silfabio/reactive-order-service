package com.fabio.orderservice.controller

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import reactor.core.publisher.Mono

/**
 * A simple controller to handle requests to the root path ("/").
 * This provides a basic health/status check to confirm the service is running,
 * preventing the default "Whitelabel Error Page".
 */
@RestController
class HomeController {

    companion object {
        private const val HOME_MESSAGE = "Reactive Order Service is running!"
    }

    @GetMapping("/")
    fun home(): Mono<String> {
        return Mono.just(HOME_MESSAGE)
    }
}
