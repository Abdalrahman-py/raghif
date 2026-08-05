package com.raghif.app.data

// Registration logic extracted from LoginScreen — pure and unit-testable. The screen
// maps the returned key through t(); the buyer entity carries demo defaults (fixed
// starting balance) until a real top-up flow exists.

/** Returns the error-string key when registration fields are invalid, null when OK. */
fun validateRegistration(phone: String, pin: String, personalId: String, name: String): String? = when {
    phone.trim().isBlank() || pin.length != 4 || personalId.trim().isBlank() || name.trim().isBlank() -> "register_error"
    else -> null
}

/** Builds a fresh buyer account: role buyer, 20 ILS starting balance so a demo purchase works immediately. */
fun newBuyer(phone: String, pin: String, personalId: String, name: String): UserEntity = UserEntity(
    id = java.util.UUID.randomUUID().toString(),
    phone = phone.trim(),
    pin = pin.trim(),
    role = "buyer",
    balance = 20, // ponytail: fixed starting balance; replace with a real top-up flow later
    personalId = personalId.trim(),
    name = name.trim()
)
