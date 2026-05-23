package com.fabio.orderservice.domain

/**
 * Represents the possible states of an order in its lifecycle.
 */
enum class OrderStatus {
    /**
     * The order has been created but is awaiting processing. This is the initial state.
     */
    PENDING,

    /**
     * The order is actively being processed (e.g., payment verification, inventory check).
     */
    PROCESSING,

    /**
     * The order has been successfully processed and is considered complete. This is a terminal state.
     */
    COMPLETED,

    /**
     * The order could not be processed due to an error. This is a terminal state.
     * This status will be used in future error-handling scenarios (e.g., with Resilience4j).
     */
    FAILED,
}
