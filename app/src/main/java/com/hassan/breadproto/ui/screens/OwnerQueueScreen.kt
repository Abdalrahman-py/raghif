package com.hassan.breadproto.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import com.hassan.breadproto.data.AppDatabase
import com.hassan.breadproto.data.PurchaseEntity
import com.hassan.breadproto.data.todayDateString
import com.hassan.breadproto.i18n.t
import com.hassan.breadproto.notify.NotifyHelper
import com.hassan.breadproto.ui.components.AppCard
import com.hassan.breadproto.ui.components.PrimaryButton
import com.hassan.breadproto.ui.components.ScreenHeader
import com.hassan.breadproto.ui.components.SecondaryButton
import com.hassan.breadproto.ui.components.StatusChip
import com.hassan.breadproto.ui.components.StatusTone
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

@Composable
fun OwnerQueueScreen(
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val db = remember { AppDatabase.getDatabase(context) }
    val storeId = AppDatabase.DEMO_STORE_ID
    val date = remember { todayDateString() }

    val store by remember { db.storeDao().getStoreById(storeId) }.collectAsState(initial = null)
    val queue by remember { db.purchaseDao().getQueueForStore(storeId, date) }.collectAsState(initial = emptyList())

    var phoneByUserId by remember { mutableStateOf<Map<String, String>>(emptyMap()) }
    LaunchedEffect(queue) {
        val ids = queue.map { it.userId }.distinct()
        phoneByUserId = ids.associateWith { id -> db.userDao().getUserById(id).first()?.phone ?: id }
    }

    val grouped = queue.groupBy { it.batchNumber }.toSortedMap()
    val nextBatchToNotify = queue.filter { it.status == "waiting" }.minByOrNull { it.batchNumber }?.batchNumber

    Scaffold { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize(), contentAlignment = Alignment.TopCenter) {
        Column(modifier = Modifier.fillMaxWidth().widthIn(max = 480.dp).padding(20.dp)) {
            ScreenHeader(title = t("buyer_queue_title"))
            Spacer(modifier = Modifier.height(4.dp))
            Text(store?.name ?: "", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(16.dp))

            if (nextBatchToNotify != null) {
                PrimaryButton(
                    text = t("notify_next_batch").format(nextBatchToNotify),
                    onClick = {
                        scope.launch {
                            val toNotify = queue.filter { it.batchNumber == nextBatchToNotify && it.status == "waiting" }
                            toNotify.forEach { db.purchaseDao().updatePurchase(it.copy(status = "notified")) }
                            val fired = NotifyHelper.notifyBatchReady(context, store?.name ?: "", notificationId = nextBatchToNotify)
                            if (!fired) {
                                android.widget.Toast.makeText(
                                    context,
                                    t("notify_permission_toast"),
                                    android.widget.Toast.LENGTH_LONG
                                ).show()
                            }
                        }
                    }
                )
                Spacer(modifier = Modifier.height(16.dp))
            }

            LazyColumn(modifier = Modifier.weight(1f, fill = false)) {
                grouped.forEach { (batchNumber, purchases) ->
                    item {
                        Text(t("batch_label").format(batchNumber), style = MaterialTheme.typography.titleMedium)
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                    items(purchases, key = { it.id }) { purchase ->
                        BuyerRow(
                            purchase = purchase,
                            phone = phoneByUserId[purchase.userId] ?: purchase.userId,
                            onMarkReceived = {
                                scope.launch { db.purchaseDao().updatePurchase(purchase.copy(status = "collected")) }
                            }
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                    item { Spacer(modifier = Modifier.height(12.dp)) }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            SecondaryButton(text = t("back_to_dashboard"), onClick = onBack)
        }
        }
    }
}

@Composable
private fun BuyerRow(purchase: PurchaseEntity, phone: String, onMarkReceived: () -> Unit) {
    val tone = when (purchase.status) {
        "notified" -> StatusTone.SUCCESS
        "collected" -> StatusTone.NEUTRAL
        else -> StatusTone.WARNING
    }
    val statusText = when (purchase.status) {
        "notified" -> t("status_notified_short")
        "collected" -> t("status_collected_short")
        else -> t("status_waiting_short")
    }
    AppCard {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(phone, style = MaterialTheme.typography.bodyLarge)
                Spacer(modifier = Modifier.height(4.dp))
                StatusChip(text = statusText, tone = tone)
            }
            if (purchase.status == "notified") {
                TextButton(onClick = onMarkReceived) {
                    Text(t("mark_received"), style = MaterialTheme.typography.labelLarge)
                }
            }
        }
    }
}
