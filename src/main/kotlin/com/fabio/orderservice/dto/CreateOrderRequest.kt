package com.fabio.orderservice.dto

import jakarta.validation.constraints.Min
import jakarta.validation.constraints.NotBlank

/**
 * Data Transfer Object for creating a new order.
 * This class defines the public API contract for an order request,
 * separating it from the internal domain model.
 */
data class CreateOrderRequest(
    @field:NotBlank(message = "Item name must not be blank")
    val itemName: String,
    @field:Min(value = 1, message = "Amount must be at least 1")
    val amount: Int,
)
