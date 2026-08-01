package com.hassan.breadproto.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity
data class PurchaseEntity(
    @PrimaryKey val id: String,
    val storeId: String,
    val userId: String,
    val purchaseDate: String,
    val batchNumber: Int,
    val status: String, // "waiting"/"notified"/"collected"
    val createdAt: Long,
    val batchRoundAtPurchase: Int = 1
)
