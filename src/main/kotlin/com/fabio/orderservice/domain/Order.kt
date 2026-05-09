package com.fabio.orderservice.domain

import com.fasterxml.jackson.annotation.JsonIgnore
import com.fasterxml.jackson.annotation.JsonProperty
import org.springframework.data.annotation.Id
import org.springframework.data.domain.Persistable
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.util.UUID

@Table("ORDERS")
data class Order(
    @Id
    @Column("id")
    @param:JsonProperty("id")
    private val _id: UUID? = null,

    @Column("ITEM_NAME")
    val itemName: String,

    @Column("AMOUNT")
    val amount: Int,

    @Column("STATUS")
    val status: OrderStatus = OrderStatus.PENDING

) : Persistable<UUID> {

    // Expose the ID via a public getter.
    override fun getId(): UUID? = _id

    @JsonIgnore
    override fun isNew(): Boolean = (this.status == OrderStatus.PENDING)

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
