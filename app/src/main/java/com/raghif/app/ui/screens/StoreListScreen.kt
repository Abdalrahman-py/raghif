package com.raghif.app.ui.screens

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
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Storefront
import androidx.compose.material3.DrawerState
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.raghif.app.data.AppDatabase
import com.raghif.app.data.StoreEntity
import com.raghif.app.data.todayDateString
import com.raghif.app.i18n.t
import com.raghif.app.session.Session
import com.raghif.app.ui.components.AppCard
import com.raghif.app.ui.components.DrawerItem
import com.raghif.app.ui.components.RaghifDrawer
import com.raghif.app.ui.components.StatusChip
import com.raghif.app.ui.components.StatusTone
import com.raghif.app.ui.theme.Spacing
import kotlinx.coroutines.launch

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
    val drawerState = rememberDrawerState(DrawerValue.Closed)

    Scaffold { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize(), contentAlignment = Alignment.TopCenter) {
        RaghifDrawer(
            drawerState = drawerState,
            header = { Text(t("app_title"), style = MaterialTheme.typography.titleLarge) },
            items = {
                DrawerItem(icon = Icons.Filled.DateRange, text = t("simulate_new_day")) {
                    Session.simulatedDayOffset += 1
                    scope.launch { drawerState.close() }
                }
                Spacer(modifier = Modifier.height(Spacing.sm))
                DrawerItem(icon = Icons.Filled.Logout, text = t("logout")) {
                    Session.currentUserId = null
                    onLogout()
                }
            }
        ) {
            Column(modifier = Modifier.fillMaxWidth().widthIn(max = 480.dp).padding(20.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = { scope.launch { drawerState.open() } }) {
                        Icon(Icons.Filled.Menu, contentDescription = t("menu_label"))
                    }
                    Text(t("store_list_title"), style = MaterialTheme.typography.titleLarge)
                }
                Spacer(modifier = Modifier.height(4.dp))
                Text("${t("today_label")}: $date", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(modifier = Modifier.height(16.dp))
                if (stores.isEmpty()) {
                    Text(
                        t("no_stores"),
                        modifier = Modifier.weight(1f, fill = false),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                LazyColumn(modifier = Modifier.weight(1f, fill = false)) {
                    items(stores, key = { it.id }) { store ->
                        StoreRow(store, onNavigateToPurchase)
                        Spacer(modifier = Modifier.height(12.dp))
                    }
                }
                }
            }
        }
        }
    }
}

@Composable
private fun StoreRow(store: StoreEntity, onNavigateToPurchase: (String) -> Unit) {
    val available = store.isOpen && store.bagsRemaining > 0
    AppCard(modifier = if (available) Modifier.clickable { onNavigateToPurchase(store.id) } else Modifier) {
        Column {
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
            if (available) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    t("bags_remaining").format(store.bagsRemaining, store.dailyBagLimit),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
