package com.raghif.app.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class RegistrationTest {

    // --- Slice 1: registration field validation ---

    @Test
    fun `valid registration fields pass validation`() {
        assertNull(validateRegistration("0599111111", "1234", "900111222", "أحمد ناصر"))
    }

    @Test
    fun `blank phone is rejected with the register error key`() {
        assertEquals("register_error", validateRegistration("   ", "1234", "900111222", "أحمد ناصر"))
    }

    @Test
    fun `pin shorter than 4 digits is rejected`() {
        assertEquals("register_error", validateRegistration("0599111111", "123", "900111222", "أحمد ناصر"))
    }

    @Test
    fun `pin longer than 4 digits is rejected`() {
        assertEquals("register_error", validateRegistration("0599111111", "12345", "900111222", "أحمد ناصر"))
    }

    @Test
    fun `blank national id is rejected`() {
        assertEquals("register_error", validateRegistration("0599111111", "1234", "  ", "أحمد ناصر"))
    }

    @Test
    fun `blank name is rejected`() {
        assertEquals("register_error", validateRegistration("0599111111", "1234", "900111222", ""))
    }

    // --- Slice 2: new buyer account factory ---

    @Test
    fun `creates a buyer-role account`() {
        val u = newBuyer("0599111111", "1234", "900111222", "أحمد ناصر")
        assertEquals("buyer", u.role)
    }

    @Test
    fun `gives the demo starting balance so a purchase works immediately`() {
        val u = newBuyer("0599111111", "1234", "900111222", "أحمد ناصر")
        assertEquals(20, u.balance)
    }

    @Test
    fun `trims all fields`() {
        val u = newBuyer(" 0599111111 ", " 1234 ", " 900111222 ", " أحمد ناصر ")
        assertEquals("0599111111", u.phone)
        assertEquals("1234", u.pin)
        assertEquals("900111222", u.personalId)
        assertEquals("أحمد ناصر", u.name)
    }

    @Test
    fun `generates a non-blank unique id per account`() {
        val first = newBuyer("0599111111", "1234", "900111222", "أحمد ناصر")
        val second = newBuyer("0599111111", "1234", "900111222", "أحمد ناصر")
        assertTrue(first.id.isNotBlank())
        assertNotEquals(first.id, second.id)
    }
}
