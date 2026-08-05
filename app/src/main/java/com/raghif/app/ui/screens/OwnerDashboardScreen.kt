package com.raghif.app.ui.screens

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material3.DrawerState
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.raghif.app.data.AppDatabase
import com.raghif.app.data.needsAllocation
import com.raghif.app.data.todayDateString
import com.raghif.app.i18n.t
import com.raghif.app.ui.components.AppCard
import com.raghif.app.ui.components.BigStatDisplay
import com.raghif.app.ui.components.DrawerItem
import com.raghif.app.ui.components.DrawerStat
import com.raghif.app.ui.components.PrimaryButton
import com.raghif.app.ui.components.RaghifDrawer
import com.raghif.app.ui.components.SecondaryButton
import com.raghif.app.ui.components.Stepper
import com.raghif.app.ui.theme.Spacing
import kotlinx.coroutines.launch

@Composable
fun OwnerDashboardScreen(
    onNavigateToQueue: () -> Unit,
    onLogout: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val db = remember { AppDatabase.getDatabase(context) }
    val storeId = AppDatabase.DEMO_STORE_ID

    val store by remember { db.storeDao().getStoreById(storeId) }.collectAsState(initial = null)
    val date = todayDateString()
    val orders by remember(date) { db.purchaseDao().getQueueForStore(storeId, date) }.collectAsState(initial = emptyList())
    val drawerState = rememberDrawerState(DrawerValue.Closed)

    // auto-navigate to the customers list once when today's allocation is already set and
    // bundles remain — the admin shouldn't land on the form first thing mid-day
    var autoNavigated by rememberSaveable { mutableStateOf(false) }
    val needsAlloc = store?.let { needsAllocation(it, date) } ?: true
    LaunchedEffect(needsAlloc) {
        if (!needsAlloc && !autoNavigated) {
            autoNavigated = true
            onNavigateToQueue()
        }
    }

    var allocation by rememberSaveable { mutableIntStateOf(0) }
    var batchSize by rememberSaveable { mutableIntStateOf(1) }

    LaunchedEffect(store?.id) {
        store?.let {
            allocation = it.dailyBagLimit
            batchSize = it.batchSize
        }
    }

    Scaffold { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize(), contentAlignment = Alignment.TopCenter) {
        RaghifDrawer(
            drawerState = drawerState,
            header = {
                Text(store?.name ?: "", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(Spacing.xs))
                Text(t("owner_dashboard_title"), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            },
            items = {
                DrawerStat(icon = Icons.Filled.Inventory2, text = "${t("remaining_label")}: ${store?.bagsRemaining ?: 0} / ${store?.dailyBagLimit ?: 0}")
                DrawerStat(icon = Icons.Filled.ReceiptLong, text = "${t("orders_count")}: ${orders.size}")
                Spacer(modifier = Modifier.height(Spacing.sm))
                DrawerItem(icon = Icons.Filled.Logout, text = t("logout")) { onLogout() }
            }
        ) {
        Column(modifier = Modifier.fillMaxWidth().widthIn(max = 480.dp).padding(20.dp)) {
        Column(modifier = Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = { scope.launch { drawerState.open() } }) {
                    Icon(Icons.Filled.Menu, contentDescription = t("menu_label"))
                }
                Text(t("owner_dashboard_title"), style = MaterialTheme.typography.titleLarge)
            }
            Spacer(modifier = Modifier.height(4.dp))
            Text(store?.name ?: "", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(20.dp))

            AppCard {
                BigStatDisplay(label = t("remaining_label"), value = "${store?.bagsRemaining ?: 0} / ${store?.dailyBagLimit ?: 0}")
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(t("purchase_window_open"), style = MaterialTheme.typography.bodyLarge)
                    Switch(
                        checked = store?.isOpen ?: false,
                        onCheckedChange = { checked ->
                            store?.let { s -> scope.launch { db.storeDao().updateStore(s.copy(isOpen = checked)) } }
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))
            AppCard {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(t("allocation_label"), style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
                    Stepper(
                        value = allocation,
                        onValueChange = { allocation = it },
                        decrementDescription = t("decrease_value"),
                        incrementDescription = t("increase_value")
                    )
                }
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(t("batch_size_label"), style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
                    Stepper(
                        value = batchSize,
                        onValueChange = { batchSize = it },
                        decrementDescription = t("decrease_value"),
                        incrementDescription = t("increase_value"),
                        min = 1
                    )
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
            SecondaryButton(
                text = t("save_allocation"),
                onClick = {
                    store?.let { s ->
                        scope.launch {
                            db.storeDao().updateStore(
                                // bumping batchRound marks this as a new batch — buyers who already
                                // got a bag today from this store can buy one more from this new batch
                                s.copy(
                                    dailyBagLimit = allocation,
                                    bagsRemaining = allocation,
                                    batchSize = batchSize,
                                    batchRound = s.batchRound + 1,
                                    allocationDate = todayDateString()
                                )
                            )
                        }
                    }
                }
            )
        }

            Spacer(modifier = Modifier.height(20.dp))
            PrimaryButton(text = t("go_to_queue"), onClick = onNavigateToQueue)
        }
        }
        }
    }
}
