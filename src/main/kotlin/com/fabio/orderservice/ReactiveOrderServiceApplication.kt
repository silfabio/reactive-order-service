package com.fabio.orderservice

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Profile
import java.sql.SQLException

@SpringBootApplication
class ReactiveOrderServiceApplication

fun main(args: Array<String>) {
    runApplication<ReactiveOrderServiceApplication>(*args)
}
