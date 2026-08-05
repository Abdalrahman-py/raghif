package com.raghif.app.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class QueueLogicTest {

    private fun user(
        id: String,
        phone: String = "0599111111",
        name: String = "أحمد ناصر",
        personalId: String = "900111222"
    ) = UserEntity(id = id, phone = phone, pin = "1234", role = "buyer", balance = 10, personalId = personalId, name = name)

    private fun purchase(
        id: String,
        userId: String,
        batch: Int = 1,
        status: String = "waiting"
    ) = PurchaseEntity(
        id = id,
        storeId = "store_1",
        userId = userId,
        purchaseDate = "2026-08-05",
        batchNumber = batch,
        status = status,
        createdAt = 0L
    )

    // --- Slice 1: admin arrival toggle (notified <-> collected) ---

    @Test
    fun `marking a notified customer as received moves them to collected`() {
        assertEquals("collected", toggleArrivalStatus("notified"))
    }

    @Test
    fun `undoing a received customer moves them back to notified`() {
        assertEquals("notified", toggleArrivalStatus("collected"))
    }

    @Test
    fun `waiting customers have no arrival action and stay waiting`() {
        assertEquals("waiting", toggleArrivalStatus("waiting"))
    }

    // --- Slice 2: next batch to notify (smallest batch with waiting customers) ---

    @Test
    fun `picks the smallest batch that still has waiting customers`() {
        val queue = listOf(
            purchase("p1", "u1", batch = 1, status = "notified"),
            purchase("p2", "u2", batch = 2, status = "waiting"),
            purchase("p3", "u3", batch = 3, status = "waiting")
        )
        assertEquals(2, nextBatchToNotify(queue))
    }

    @Test
    fun `ignores batches where everyone was already notified or collected`() {
        val queue = listOf(
            purchase("p1", "u1", batch = 1, status = "notified"),
            purchase("p2", "u2", batch = 1, status = "collected"),
            purchase("p3", "u3", batch = 2, status = "waiting")
        )
        assertEquals(2, nextBatchToNotify(queue))
    }

    @Test
    fun `returns null when no one is waiting`() {
        val queue = listOf(
            purchase("p1", "u1", batch = 1, status = "notified"),
            purchase("p2", "u2", batch = 1, status = "collected")
        )
        assertNull(nextBatchToNotify(queue))
    }

    @Test
    fun `returns null for an empty queue`() {
        assertNull(nextBatchToNotify(emptyList()))
    }

    // --- Slice 3: admin search (name, phone, or national ID) ---

    @Test
    fun `blank query returns the whole queue in order`() {
        val queue = listOf(purchase("p1", "u1"), purchase("p2", "u2"))
        val users = mapOf("u1" to user("u1"), "u2" to user("u2"))
        assertEquals(queue, filterQueue(queue, users, "   "))
    }

    @Test
    fun `blank query keeps purchases whose user is unknown`() {
        val queue = listOf(purchase("p1", "ghost"))
        assertEquals(queue, filterQueue(queue, emptyMap(), "  "))
    }

    @Test
    fun `matches by name substring`() {
        val queue = listOf(purchase("p1", "u1"), purchase("p2", "u2"))
        val users = mapOf(
            "u1" to user("u1", name = "أحمد ناصر"),
            "u2" to user("u2", name = "سامي خالد")
        )
        assertEquals(listOf(queue[0]), filterQueue(queue, users, "ناصر"))
    }

    @Test
    fun `matches by name ignoring case`() {
        val queue = listOf(purchase("p1", "u1"), purchase("p2", "u2"))
        val users = mapOf(
            "u1" to user("u1", name = "Ali"),
            "u2" to user("u2", name = "Sami")
        )
        assertEquals(listOf(queue[0]), filterQueue(queue, users, "ali"))
    }

    @Test
    fun `matches by phone number substring`() {
        val queue = listOf(purchase("p1", "u1"), purchase("p2", "u2"))
        val users = mapOf(
            "u1" to user("u1", phone = "0599111111"),
            "u2" to user("u2", phone = "0599222222")
        )
        assertEquals(listOf(queue[0]), filterQueue(queue, users, "059911"))
    }

    @Test
    fun `matches by national ID number substring`() {
        val queue = listOf(purchase("p1", "u1"), purchase("p2", "u2"))
        val users = mapOf(
            "u1" to user("u1", personalId = "900111222"),
            "u2" to user("u2", personalId = "900333444")
        )
        assertEquals(listOf(queue[0]), filterQueue(queue, users, "900111"))
    }

    @Test
    fun `returns empty when nothing matches`() {
        val queue = listOf(purchase("p1", "u1"))
        val users = mapOf("u1" to user("u1"))
        assertEquals(emptyList<PurchaseEntity>(), filterQueue(queue, users, "999"))
    }

    @Test
    fun `trims surrounding whitespace from the query`() {
        val queue = listOf(purchase("p1", "u1"))
        val users = mapOf("u1" to user("u1", name = "أحمد ناصر"))
        assertEquals(queue, filterQueue(queue, users, "  أحمد  "))
    }

    // --- Estimated ready time (createdAt + batch x 10-min interval) ---

    @Test
    fun `batch one is ready one interval after creation`() {
        // 1,000,000 ms + 10 min (600,000 ms)
        assertEquals(1_600_000L, estimatedReadyAtMillis(1_000_000L, 1))
    }

    @Test
    fun `batch two is ready two intervals after creation`() {
        // 1,000,000 ms + 20 min (1,200,000 ms)
        assertEquals(2_200_000L, estimatedReadyAtMillis(1_000_000L, 2))
    }

    @Test
    fun `batch zero is ready at creation time`() {
        assertEquals(1_000_000L, estimatedReadyAtMillis(1_000_000L, 0))
    }

    // --- Admin landing: when to ask for today's allocation ---

    private fun store(allocationDate: String, bagsRemaining: Int = 300) = StoreEntity(
        id = "store_1",
        name = "Test Bakery",
        isOpen = true,
        dailyBagLimit = 300,
        bagsRemaining = bagsRemaining,
        allocationDate = allocationDate
    )

    @Test
    fun `same day with bundles left needs no allocation`() {
        assertFalse(needsAllocation(store("2026-08-05"), "2026-08-05"))
    }

    @Test
    fun `a new day needs allocation even with bundles left`() {
        assertTrue(needsAllocation(store("2026-08-04"), "2026-08-05"))
    }

    @Test
    fun `sold out on the same day needs allocation`() {
        assertTrue(needsAllocation(store("2026-08-05", bagsRemaining = 0), "2026-08-05"))
    }

    @Test
    fun `a store with no allocation date yet needs allocation`() {
        assertTrue(needsAllocation(store(""), "2026-08-05"))
    }
}
