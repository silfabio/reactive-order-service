package com.fabio.orderservice

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class ReactiveOrderServiceApplication

fun main(args: Array<String>) {
    runApplication<ReactiveOrderServiceApplication>(*args)
}
