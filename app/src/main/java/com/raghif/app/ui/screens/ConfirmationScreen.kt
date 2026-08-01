package com.raghif.app.ui.screens

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.raghif.app.data.AppDatabase
import com.raghif.app.i18n.t
import com.raghif.app.ui.components.AppCard
import com.raghif.app.ui.components.PrimaryButton
import com.raghif.app.ui.components.ScreenHeader
import com.raghif.app.ui.components.StatusChip
import com.raghif.app.ui.components.StatusTone
import kotlinx.coroutines.flow.first
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private const val BATCH_INTERVAL_MINUTES = 10
private val READY_TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm")

@Composable
fun ConfirmationScreen(
    purchaseId: String,
    onNavigateToStoreList: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val db = remember { AppDatabase.getDatabase(context) }

    val purchase by remember { db.purchaseDao().getPurchaseById(purchaseId) }.collectAsState(initial = null)
    var position by remember { mutableIntStateOf(0) }

    LaunchedEffect(purchase?.storeId, purchase?.purchaseDate) {
        val p = purchase ?: return@LaunchedEffect
        val queue = db.purchaseDao().getQueueForStore(p.storeId, p.purchaseDate).first()
        position = queue.indexOfFirst { it.id == purchaseId } + 1
    }

    val readyAtLabel = purchase?.let { p ->
        val estimatedReadyAt = p.createdAt + p.batchNumber * BATCH_INTERVAL_MINUTES * 60_000L
        Instant.ofEpochMilli(estimatedReadyAt).atZone(ZoneId.systemDefault()).format(READY_TIME_FORMAT)
    } ?: ""

    Scaffold { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize(), contentAlignment = Alignment.TopCenter) {
        Column(modifier = Modifier.fillMaxWidth().widthIn(max = 480.dp).padding(20.dp)) {
            ScreenHeader(title = t("confirmation_title"))
            Spacer(modifier = Modifier.height(20.dp))

            if (position > 0) {
                StatusChip(text = "${t("queue_position")} $position", tone = StatusTone.NEUTRAL)
                Spacer(modifier = Modifier.height(20.dp))
            }

            when (purchase?.status) {
                "waiting" -> {
                    Text(t("status_waiting"), style = MaterialTheme.typography.bodyLarge)
                    Spacer(modifier = Modifier.height(20.dp))
                    AppCard {
                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(t("estimated_time"), style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                readyAtLabel,
                                style = MaterialTheme.typography.displayLarge,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
                "notified", "collected" -> {
                    AppCard {
                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(t("status_notified"), style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.primary)
                        }
                    }
                }
                else -> Unit
            }

            Spacer(modifier = Modifier.weight(1f))
            PrimaryButton(text = t("return_to_stores"), onClick = onNavigateToStoreList)
        }
        }
    }
}
