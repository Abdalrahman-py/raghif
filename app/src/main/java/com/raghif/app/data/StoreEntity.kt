package com.raghif.app.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity
data class StoreEntity(
    @PrimaryKey val id: String,
    val name: String,
    val isOpen: Boolean,
    val dailyBagLimit: Int,
    val bagsRemaining: Int,
    val batchSize: Int = 20,
    // bumped every time the owner tops up allocation — a purchase made under an older
    // round no longer blocks a same-day repurchase once the round has moved on
    val batchRound: Int = 1
)
