package com.fabio.orderservice.exception

import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.bind.support.WebExchangeBindException

/**
 * A global exception handler to provide consistent, structured error responses across the application.
 */
@RestControllerAdvice
class GlobalExceptionHandler {
    /**
     * Handles validation exceptions (`@Valid` failures).
     *
     * @param ex The exception thrown when validation fails.
     * @return A ResponseEntity with a 400 Bad Request status and a structured error body.
     */
    @ExceptionHandler(WebExchangeBindException::class)
    fun handleValidationExceptions(ex: WebExchangeBindException): ResponseEntity<Map<String, Any>> {
        val errors =
            ex.bindingResult.allErrors.map { error ->
                error.defaultMessage ?: "Invalid value"
            }

        val errorBody =
            mapOf(
                "status" to HttpStatus.BAD_REQUEST.value(),
                "error" to "Bad Request",
                "errors" to errors,
            )

        return ResponseEntity.badRequest().body(errorBody)
    }
}
