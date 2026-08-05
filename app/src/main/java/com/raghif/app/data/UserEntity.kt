package com.raghif.app.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity
data class UserEntity(
    @PrimaryKey val id: String,
    val phone: String,
    val pin: String,
    val role: String, // "buyer" or "owner"
    val balance: Int = 0, // fake prepaid balance, ILS
    val personalId: String = "", // national/personal ID, collected once at first-time registration
    val name: String = "" // collected at registration, lets the owner search the queue by name
)
