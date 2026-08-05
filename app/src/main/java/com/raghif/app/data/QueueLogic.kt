package com.raghif.app.data

import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

// Pure queue logic, extracted from OwnerQueueScreen so the admin state machine is
// unit-testable. Statuses: waiting (bought, not called) -> notified (batch notif sent,
// awaiting arrival) -> collected (admin checked them in).
const val STATUS_WAITING = "waiting"
const val STATUS_NOTIFIED = "notified"
const val STATUS_COLLECTED = "collected"

/** Admin arrival check: notified (pending) <-> collected (arrived). Waiting rows have no action. */
fun toggleArrivalStatus(status: String): String = when (status) {
    STATUS_NOTIFIED -> STATUS_COLLECTED
    STATUS_COLLECTED -> STATUS_NOTIFIED
    else -> status
}

/** Smallest batch number that still has waiting customers — the one the admin should notify next. */
fun nextBatchToNotify(queue: List<PurchaseEntity>): Int? =
    queue.filter { it.status == STATUS_WAITING }.minByOrNull { it.batchNumber }?.batchNumber

/** Admin search: matches name, phone, or national ID (رقم الهوية). Blank query returns the queue as-is. */
fun filterQueue(
    queue: List<PurchaseEntity>,
    usersByUserId: Map<String, UserEntity>,
    query: String
): List<PurchaseEntity> {
    val q = query.trim()
    if (q.isEmpty()) return queue
    return queue.filter { p ->
        val u = usersByUserId[p.userId]
        u?.phone?.contains(q) == true ||
            u?.name?.contains(q, ignoreCase = true) == true ||
            u?.personalId?.contains(q) == true
    }
}

const val BATCH_INTERVAL_MINUTES = 10

/** Estimated ready time (epoch millis): createdAt + batch x interval — batch is that bakery's queue position. */
fun estimatedReadyAtMillis(createdAt: Long, batchNumber: Int): Long =
    createdAt + batchNumber * BATCH_INTERVAL_MINUTES * 60_000L

private val READY_TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm")

/** Formats epoch millis as HH:mm in the device's local time. */
fun formatReadyTime(millis: Long): String =
    Instant.ofEpochMilli(millis).atZone(ZoneId.systemDefault()).format(READY_TIME_FORMAT)

/** True when the admin must set today's allocation first: it's a new day, or the current bundles are gone. */
fun needsAllocation(store: StoreEntity, today: String): Boolean =
    store.allocationDate != today || store.bagsRemaining <= 0
