package com.raghif.app.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity
data class UserEntity(
    @PrimaryKey val id: String,
    val phone: String,
    val pin: String,
    val role: String, // "buyer" or "owner"
    val balance: Int = 0 // fake prepaid balance, ILS
)
