package com.fabio.orderservice.controller

import com.fabio.orderservice.domain.Order
import com.fabio.orderservice.domain.OrderStatus
import com.fabio.orderservice.dto.CreateOrderRequest
import com.fabio.orderservice.exception.GlobalExceptionHandler
import com.fabio.orderservice.service.OrderService
import com.ninjasquad.springmockk.MockkBean
import io.kotest.core.spec.style.FunSpec
import io.kotest.datatest.withData
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.mockk.every
import org.springframework.boot.test.autoconfigure.web.reactive.WebFluxTest
import org.springframework.context.annotation.Import
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.test.web.reactive.server.WebTestClient
import org.springframework.test.web.reactive.server.expectBody
import reactor.core.publisher.Mono
import java.util.UUID

@WebFluxTest(OrderController::class)
@Import(GlobalExceptionHandler::class)
class OrderControllerTest(
    private val webTestClient: WebTestClient,
    @MockkBean private val orderService: OrderService,
) : FunSpec({

        val orderId = UUID.randomUUID()
        val sampleOrder =
            Order(
                _id = orderId,
                itemName = "Test Item",
                amount = 10,
                status = OrderStatus.PENDING,
            )

        test("POST /orders should create a new order") {
            val createRequest = CreateOrderRequest(itemName = "New Item", amount = 5)
            val createdOrder = sampleOrder.copy(itemName = createRequest.itemName, amount = createRequest.amount)

            every { orderService.createOrder(any()) } returns Mono.just(createdOrder)

            webTestClient
                .post()
                .uri("/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(createRequest)
                .exchange()
                .expectStatus()
                .isCreated
                .expectBody(Order::class.java)
                .value {
                    it.id shouldBe createdOrder.id
                    it.itemName shouldBe createRequest.itemName
                    it.amount shouldBe createRequest.amount
                    it.status shouldBe OrderStatus.PENDING
                }
        }

        context("POST /orders should return 400 for invalid requests") {
            withData(
                @Suppress("ktlint:standard:max-line-length")
                mapOf(
                    "blank item name" to
                        (CreateOrderRequest(itemName = "", amount = 1) to listOf("Item name must not be blank")),
                    "amount below minimum" to
                        (CreateOrderRequest(itemName = "Valid Item", amount = 0) to listOf("Amount must be at least 1")),
                    "blank item name and amount below minimum" to
                        (
                            CreateOrderRequest(
                                itemName = "",
                                amount = 0,
                            ) to listOf("Item name must not be blank", "Amount must be at least 1")
                        ),
                ),
            ) { (request, expectedErrors) ->
                webTestClient
                    .post()
                    .uri("/orders")
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus()
                    .isBadRequest
                    .expectBody<Map<String, Any>>()
                    .value { response ->
                        response["status"] shouldBe HttpStatus.BAD_REQUEST.value()
                        val errors = response["errors"] as List<*>
                        expectedErrors.forEach { errors shouldContain it }
                    }
            }
        }

        test("GET /orders/{id} should return an order if found") {
            every { orderService.findById(orderId) } returns Mono.just(sampleOrder)

            webTestClient
                .get()
                .uri("/orders/{id}", orderId)
                .exchange()
                .expectStatus()
                .isOk
                .expectBody(Order::class.java)
                .value {
                    it.id shouldBe sampleOrder.id
                    it.itemName shouldBe sampleOrder.itemName
                }
        }

        test("GET /orders/{id} should return 404 if order not found") {
            every { orderService.findById(any()) } returns Mono.empty()

            webTestClient
                .get()
                .uri("/orders/{id}", UUID.randomUUID())
                .exchange()
                .expectStatus()
                .isNotFound
                .expectBody()
                .isEmpty
        }
    })
