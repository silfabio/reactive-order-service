package com.fabio.orderservice.controller

import com.fabio.orderservice.domain.Order
import com.fabio.orderservice.dto.CreateOrderRequest
import com.fabio.orderservice.service.OrderService
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import reactor.core.publisher.Mono
import java.util.UUID

@RestController
@RequestMapping("/orders")
class OrderController(private val orderService: OrderService) {

    @PostMapping
    fun create(@Valid @RequestBody request: CreateOrderRequest): Mono<ResponseEntity<Order>> {
        val newOrder = Order(
            itemName = request.itemName,
            amount = request.amount
        )
        return orderService.createOrder(newOrder)
            .map { createdOrder ->
                ResponseEntity.status(HttpStatus.CREATED).body(createdOrder)
            }
    }

    @GetMapping("/{id}")
    fun getOrder(@PathVariable id: UUID): Mono<ResponseEntity<Order>> =
        orderService.findById(id)
            .map { ResponseEntity.ok(it) }
            .defaultIfEmpty(ResponseEntity.notFound().build())
}
