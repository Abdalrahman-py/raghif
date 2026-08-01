package com.hassan.breadproto.session

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

// ponytail: single mutable global instead of DI/ViewModel — fine for a one-user-at-a-time
// demo prototype. Real app needs a proper auth/session layer.
object Session {
    var currentUserId: String? = null

    // demo-only "fast forward" control (see StoreListScreen's simulate-new-day button) —
    // in-memory so it resets on process death, that's fine for a live demo
    var simulatedDayOffset by mutableStateOf(0)
}
