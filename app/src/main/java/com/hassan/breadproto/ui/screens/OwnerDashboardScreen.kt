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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
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
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.hassan.breadproto.data.AppDatabase
import com.hassan.breadproto.i18n.t
import com.hassan.breadproto.ui.components.AppCard
import com.hassan.breadproto.ui.components.BigStatDisplay
import com.hassan.breadproto.ui.components.PrimaryButton
import com.hassan.breadproto.ui.components.ScreenHeader
import com.hassan.breadproto.ui.components.SecondaryButton
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

    var allocationText by remember { mutableStateOf("") }
    var batchSizeText by remember { mutableStateOf("") }

    LaunchedEffect(store?.id) {
        store?.let {
            allocationText = it.dailyBagLimit.toString()
            batchSizeText = it.batchSize.toString()
        }
    }

    Scaffold { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize(), contentAlignment = Alignment.TopCenter) {
        Column(modifier = Modifier.fillMaxWidth().widthIn(max = 480.dp).padding(20.dp)) {
        Column(modifier = Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            ScreenHeader(title = t("owner_dashboard_title"))
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
            OutlinedTextField(
                value = allocationText,
                onValueChange = { allocationText = it.filter(Char::isDigit) },
                label = { Text(t("allocation_label")) },
                singleLine = true,
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(12.dp))
            OutlinedTextField(
                value = batchSizeText,
                onValueChange = { batchSizeText = it.filter(Char::isDigit) },
                label = { Text(t("batch_size_label")) },
                singleLine = true,
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(12.dp))
            SecondaryButton(
                text = t("save_allocation"),
                onClick = {
                    val allocation = allocationText.toIntOrNull() ?: return@SecondaryButton
                    val batchSize = batchSizeText.toIntOrNull() ?: return@SecondaryButton
                    store?.let { s ->
                        scope.launch {
                            db.storeDao().updateStore(
                                // bumping batchRound marks this as a new batch — buyers who already
                                // got a bag today from this store can buy one more from this new batch
                                s.copy(dailyBagLimit = allocation, bagsRemaining = allocation, batchSize = batchSize, batchRound = s.batchRound + 1)
                            )
                        }
                    }
                }
            )
        }

            Spacer(modifier = Modifier.height(20.dp))
            PrimaryButton(text = t("go_to_queue"), onClick = onNavigateToQueue)
            Spacer(modifier = Modifier.height(12.dp))
            SecondaryButton(text = t("logout"), onClick = onLogout)
        }
        }
    }
}
