package com.fabio.orderservice.domain

import com.fasterxml.jackson.annotation.JsonIgnore
import com.fasterxml.jackson.annotation.JsonProperty
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.Transient
import org.springframework.data.domain.Persistable
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.util.UUID

@Table("ORDERS")
data class Order(
    // Tell Jackson to use the JSON field "id" for this private constructor property.
    @Id
    @Column("id")
    @JsonProperty("id")
    private val _id: UUID? = null,

    @Column("ITEM_NAME")
    val itemName: String,

    @Column("AMOUNT")
    val amount: Int,

    @Column("STATUS")
    val status: OrderStatus = OrderStatus.PENDING,

    ) : Persistable<UUID> {

    @Transient
    private var _isNew: Boolean = true

    // Expose the ID via a public getter, but don't use @JsonProperty here to avoid conflicts.
    override fun getId(): UUID? = _id

    // Tell Jackson to completely ignore this method during serialization.
    @JsonIgnore
    override fun isNew(): Boolean = _isNew

    fun saved(): Order {
        this._isNew = false
        return this
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as Order
        return getId() == other.getId()
    }

    override fun hashCode(): Int {
        return getId()?.hashCode() ?: 0
    }
}
