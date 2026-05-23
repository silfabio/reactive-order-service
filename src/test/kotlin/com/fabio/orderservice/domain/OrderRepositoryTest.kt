package com.fabio.orderservice.domain

import com.fabio.orderservice.SpringTestSpec
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import reactor.test.StepVerifier

class OrderRepositoryTest(
    private val repository: OrderRepository,
) : SpringTestSpec() {
    init {
        describe("OrderRepository Persistence") {

            it("should save and retrieve an order") {
                val order =
                    Order(
                        itemName = "Steam Deck OLED",
                        amount = 1,
                        status = OrderStatus.PENDING,
                    )

                // Save then Find to verify round-trip
                val saveAndFind =
                    repository
                        .save(order)
                        .flatMap { saved -> repository.findById(saved.id!!) }

                StepVerifier
                    .create(saveAndFind)
                    .assertNext { found ->
                        found.id.shouldNotBeNull()
                        found.itemName shouldBe "Steam Deck OLED"
                        found.status shouldBe OrderStatus.PENDING
                    }.verifyComplete()
            }

            it("should find all saved orders") {
                // Clear or setup specific state
                val setup =
                    repository
                        .deleteAll()
                        .thenMany(
                            repository.saveAll(
                                listOf(
                                    Order(itemName = "A", amount = 1, status = OrderStatus.PENDING),
                                    Order(itemName = "B", amount = 2, status = OrderStatus.PENDING),
                                ),
                            ),
                        )

                val findAll = setup.thenMany(repository.findAll())

                StepVerifier
                    .create(findAll)
                    .expectNextCount(2)
                    .verifyComplete()
            }
        }
    }
}
