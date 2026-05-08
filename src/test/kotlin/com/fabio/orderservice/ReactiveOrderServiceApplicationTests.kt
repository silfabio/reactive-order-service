package com.fabio.orderservice

import io.kotest.core.spec.style.DescribeSpec
import org.springframework.boot.test.context.SpringBootTest

@SpringBootTest
class ReactiveOrderServiceApplicationTests : DescribeSpec({
    describe("Application Context") {
        it("should load successfully") {
            // If the code reaches here, the context started
        }
    }
})