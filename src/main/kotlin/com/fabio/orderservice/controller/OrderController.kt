package com.fabio.orderservice.controller

import com.fabio.orderservice.domain.Order
import com.fabio.orderservice.dto.CreateOrderRequest
import com.fabio.orderservice.service.OrderService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.media.Content
import io.swagger.v3.oas.annotations.media.Schema
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import reactor.core.publisher.Mono
import java.util.UUID

@RestController
@RequestMapping("/orders")
@Tag(name = "Order API", description = "Endpoints for managing orders")
class OrderController(private val orderService: OrderService) {

    @Operation(summary = "Create a new order", description = "Creates a new order and publishes an event.")
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "201",
                description = "Order created successfully",
                content = [Content(mediaType = MediaType.APPLICATION_JSON_VALUE, schema = Schema(implementation = Order::class))]
            ),
            ApiResponse(
                responseCode = "400",
                description = "Invalid request body",
                content = [Content()]
            )
        ]
    )
    @PostMapping
    fun create(@Valid @RequestBody request: CreateOrderRequest): Mono<ResponseEntity<Order>> {
        // Map the DTO to the internal domain object
        val newOrder = Order(
            itemName = request.itemName,
            amount = request.amount
        )
        return orderService.createOrder(newOrder)
            .map { createdOrder ->
                ResponseEntity.status(HttpStatus.CREATED).body(createdOrder)
            }
    }

    @Operation(summary = "Get an order by its ID", description = "Retrieves a single order based on its UUID.")
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Order found",
                content = [Content(mediaType = MediaType.APPLICATION_JSON_VALUE, schema = Schema(implementation = Order::class))]
            ),
            ApiResponse(
                responseCode = "404",
                description = "Order not found",
                content = [Content()]
            )
        ]
    )
    @GetMapping("/{id}")
    fun getOrder(
        @Parameter(description = "The UUID of the order to retrieve", required = true)
        @PathVariable id: UUID
    ): Mono<ResponseEntity<Order>> =
        orderService.findById(id)
            .map { ResponseEntity.ok(it) }
            .defaultIfEmpty(ResponseEntity.notFound().build())
}
