package com.hassan.breadproto.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Storefront
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.hassan.breadproto.data.AppDatabase
import com.hassan.breadproto.data.StoreEntity
import com.hassan.breadproto.data.todayDateString
import com.hassan.breadproto.i18n.t
import com.hassan.breadproto.session.Session
import com.hassan.breadproto.ui.components.AppCard
import com.hassan.breadproto.ui.components.ScreenHeader
import com.hassan.breadproto.ui.components.SecondaryButton
import com.hassan.breadproto.ui.components.StatusChip
import com.hassan.breadproto.ui.components.StatusTone

@Composable
fun StoreListScreen(
    onNavigateToPurchase: (storeId: String) -> Unit,
    onLogout: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val db = remember { AppDatabase.getDatabase(context) }
    val stores by remember { db.storeDao().getAllStores() }.collectAsState(initial = emptyList())
    val date = todayDateString()

    Scaffold { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize(), contentAlignment = Alignment.TopCenter) {
        Column(modifier = Modifier.fillMaxWidth().widthIn(max = 480.dp).padding(20.dp)) {
            ScreenHeader(title = t("store_list_title"))
            Spacer(modifier = Modifier.height(4.dp))
            Text("${t("today_label")}: $date", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(16.dp))
            LazyColumn(modifier = Modifier.weight(1f, fill = false)) {
                items(stores, key = { it.id }) { store ->
                    StoreRow(store, onNavigateToPurchase)
                    Spacer(modifier = Modifier.height(12.dp))
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            SecondaryButton(text = t("logout"), onClick = { Session.currentUserId = null; onLogout() })
            Spacer(modifier = Modifier.height(8.dp))
            // demo-only: fast-forwards the "day" so the 1-bag-per-day limit can be shown resetting
            SecondaryButton(text = t("simulate_new_day"), onClick = { Session.simulatedDayOffset += 1 })
        }
        }
    }
}

@Composable
private fun StoreRow(store: StoreEntity, onNavigateToPurchase: (String) -> Unit) {
    val available = store.isOpen && store.bagsRemaining > 0
    AppCard(modifier = if (available) Modifier.clickable { onNavigateToPurchase(store.id) } else Modifier) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Filled.Storefront,
                    contentDescription = null,
                    tint = if (available) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(store.name, style = MaterialTheme.typography.titleMedium)
            }
            StatusChip(
                text = if (available) t("available") else t("sold_out"),
                tone = if (available) StatusTone.SUCCESS else StatusTone.DANGER
            )
        }
    }
}
