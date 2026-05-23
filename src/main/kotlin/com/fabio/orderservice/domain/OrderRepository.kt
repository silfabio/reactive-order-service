package com.fabio.orderservice.domain

import org.springframework.data.repository.reactive.ReactiveCrudRepository
import org.springframework.stereotype.Repository
import java.util.UUID

@Repository
interface OrderRepository : ReactiveCrudRepository<Order, UUID>
