package com.raghif.app.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DrawerState
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.raghif.app.data.AppDatabase
import com.raghif.app.data.PurchaseEntity
import com.raghif.app.data.STATUS_COLLECTED
import com.raghif.app.data.STATUS_NOTIFIED
import com.raghif.app.data.STATUS_WAITING
import com.raghif.app.data.UserEntity
import com.raghif.app.data.filterQueue
import com.raghif.app.data.nextBatchToNotify
import com.raghif.app.data.todayDateString
import com.raghif.app.data.toggleArrivalStatus
import com.raghif.app.i18n.t
import com.raghif.app.notify.NotifyHelper
import com.raghif.app.ui.components.AppCard
import com.raghif.app.ui.components.DrawerItem
import com.raghif.app.ui.components.DrawerStat
import com.raghif.app.ui.components.PrimaryButton
import com.raghif.app.ui.components.RaghifDrawer
import com.raghif.app.ui.components.StatusChip
import com.raghif.app.ui.components.StatusTone
import com.raghif.app.ui.components.showAppToast
import com.raghif.app.ui.theme.Spacing
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

@Composable
fun OwnerQueueScreen(
    onBack: () -> Unit,
    onLogout: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val db = remember { AppDatabase.getDatabase(context) }
    val storeId = AppDatabase.DEMO_STORE_ID
    val date = remember { todayDateString() }

    val store by remember { db.storeDao().getStoreById(storeId) }.collectAsState(initial = null)
    val queue by remember { db.purchaseDao().getQueueForStore(storeId, date) }.collectAsState(initial = emptyList())

    var usersByUserId by remember { mutableStateOf<Map<String, UserEntity>>(emptyMap()) }
    LaunchedEffect(queue) {
        val ids = queue.map { it.userId }.distinct()
        usersByUserId = ids.mapNotNull { id -> db.userDao().getUserById(id).first()?.let { id to it } }.toMap()
    }

    var query by remember { mutableStateOf("") }
    val filteredQueue = filterQueue(queue, usersByUserId, query)

    val grouped = filteredQueue.groupBy { it.batchNumber }.toSortedMap()
    val nextBatch = nextBatchToNotify(queue)
    val buyers = usersByUserId
    val drawerState = rememberDrawerState(DrawerValue.Closed)

    Scaffold(
        floatingActionButton = {
            // square-ish force-add: back to the dashboard's allocation form (the حفظ screen)
            FloatingActionButton(
                onClick = onBack,
                shape = MaterialTheme.shapes.small,
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary
            ) {
                Icon(Icons.Filled.Add, contentDescription = t("fab_add_allocation"))
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize(), contentAlignment = Alignment.TopCenter) {
        RaghifDrawer(
            drawerState = drawerState,
            header = {
                Text(store?.name ?: "", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(Spacing.xs))
                Text(t("buyer_queue_title"), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            },
            items = {
                DrawerStat(icon = Icons.Filled.Inventory2, text = "${t("remaining_label")}: ${store?.bagsRemaining ?: 0} / ${store?.dailyBagLimit ?: 0}")
                DrawerStat(icon = Icons.Filled.ReceiptLong, text = "${t("orders_count")}: ${queue.size}")
                Spacer(modifier = Modifier.height(Spacing.sm))
                DrawerItem(icon = Icons.Filled.Logout, text = t("logout")) { onLogout() }
            }
        ) {
        Column(modifier = Modifier.fillMaxWidth().widthIn(max = 480.dp).padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = { scope.launch { drawerState.open() } }) {
                    Icon(Icons.Filled.Menu, contentDescription = t("menu_label"))
                }
                Text(t("buyer_queue_title"), style = MaterialTheme.typography.titleLarge)
            }
            Spacer(modifier = Modifier.height(4.dp))
            Text(store?.name ?: "", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(16.dp))

            if (queue.isEmpty()) {
                Text(
                    t("queue_empty"),
                    modifier = Modifier.weight(1f),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else {
            OutlinedTextField(
                value = query,
                onValueChange = { query = it },
                label = { Text(t("search_label")) },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))

            if (filteredQueue.isEmpty() && query.isNotBlank()) {
                Text(t("no_results"), modifier = Modifier.weight(1f))
            } else {
                LazyColumn(modifier = Modifier.weight(1f)) {
                    grouped.forEach { (batchNumber, purchases) ->
                        item {
                            Text(t("batch_label").format(batchNumber), style = MaterialTheme.typography.titleMedium)
                            Spacer(modifier = Modifier.height(8.dp))
                        }
                        items(purchases, key = { it.id }) { purchase ->
                            BuyerRow(
                                purchase = purchase,
                                name = buyers[purchase.userId]?.name ?: "",
                                phone = buyers[purchase.userId]?.phone ?: purchase.userId,
                                personalId = buyers[purchase.userId]?.personalId ?: "",
                                onToggleArrival = {
                                    scope.launch {
                                        db.purchaseDao().updatePurchase(purchase.copy(status = toggleArrivalStatus(purchase.status)))
                                    }
                                }
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                        }
                        item { Spacer(modifier = Modifier.height(12.dp)) }
                    }
                }
            }
            }

            Spacer(modifier = Modifier.height(8.dp))
            if (nextBatch != null) {
                PrimaryButton(
                    text = t("notify_next_batch").format(nextBatch),
                    onClick = {
                        scope.launch {
                            val toNotify = queue.filter { it.batchNumber == nextBatch && it.status == STATUS_WAITING }
                            if (!NotifyHelper.hasPermission(context)) {
                                showAppToast(context, t("notify_permission_toast"))
                            } else {
                                toNotify.forEach {
                                    db.purchaseDao().updatePurchase(it.copy(status = STATUS_NOTIFIED))
                                    // unique id per purchase — a shared batch id would collapse all 20 notifications into one
                                    NotifyHelper.notifyBatchReady(context, store?.name ?: "", notificationId = it.id.hashCode())
                                }
                            }
                        }
                    }
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
        }
        }
    }
}

@Composable
private fun BuyerRow(
    purchase: PurchaseEntity,
    name: String,
    phone: String,
    personalId: String,
    onToggleArrival: () -> Unit
) {
    val tone = when (purchase.status) {
        STATUS_NOTIFIED -> StatusTone.SUCCESS
        STATUS_COLLECTED -> StatusTone.NEUTRAL
        else -> StatusTone.WARNING
    }
    val statusText = when (purchase.status) {
        STATUS_NOTIFIED -> t("status_notified_short")
        STATUS_COLLECTED -> t("status_collected_short")
        else -> t("status_waiting_short")
    }
    AppCard(modifier = Modifier.heightIn(min = 56.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(name.ifBlank { phone }, style = MaterialTheme.typography.bodyLarge)
                if (name.isNotBlank()) {
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(phone, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                if (personalId.isNotBlank()) {
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        "${t("personal_id_label")}: $personalId",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Spacer(modifier = Modifier.height(6.dp))
                StatusChip(text = statusText, tone = tone)
            }
            when (purchase.status) {
                STATUS_NOTIFIED -> Button(
                    onClick = onToggleArrival,
                    modifier = Modifier.height(48.dp),
                    shape = MaterialTheme.shapes.medium,
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                ) {
                    Text(t("mark_received"), style = MaterialTheme.typography.labelLarge)
                }
                STATUS_COLLECTED -> Button(
                    onClick = onToggleArrival,
                    modifier = Modifier.height(48.dp),
                    shape = MaterialTheme.shapes.medium,
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary)
                ) {
                    Text(t("undo_received"), style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSecondary)
                }
            }
        }
    }
}
