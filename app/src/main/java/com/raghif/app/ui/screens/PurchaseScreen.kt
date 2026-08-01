package com.raghif.app.ui.screens

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
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
import androidx.compose.ui.unit.dp
import com.raghif.app.data.AppDatabase
import com.raghif.app.data.PurchaseEntity
import com.raghif.app.data.todayDateString
import com.raghif.app.i18n.t
import com.raghif.app.session.Session
import com.raghif.app.ui.components.AppCard
import com.raghif.app.ui.components.BigStatDisplay
import com.raghif.app.ui.components.PrimaryButton
import com.raghif.app.ui.components.ScreenHeader
import com.raghif.app.ui.components.SecondaryButton
import com.raghif.app.ui.components.StatusChip
import com.raghif.app.ui.components.StatusTone
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.util.UUID

private const val BREAD_PRICE_ILS = 3

@Composable
fun PurchaseScreen(
    storeId: String,
    onNavigateToConfirmation: (purchaseId: String) -> Unit,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val db = remember { AppDatabase.getDatabase(context) }
    val userId = Session.currentUserId
    val date = todayDateString() // re-read each recomposition so the "simulate new day" demo button takes effect

    val store by remember { db.storeDao().getStoreById(storeId) }.collectAsState(initial = null)
    val user by remember { db.userDao().getUserById(userId ?: "") }.collectAsState(initial = null)

    var isPaying by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var todayPurchase by remember { mutableStateOf<PurchaseEntity?>(null) }
    var checkedExisting by remember { mutableStateOf(false) }

    LaunchedEffect(userId, date) {
        if (userId == null) return@LaunchedEffect
        todayPurchase = db.purchaseDao().findLatestForUserDate(userId, date)
        checkedExisting = true
    }

    // one bag per ID per day, across every store — the only escape hatch is the owner
    // topping up allocation at THIS store after the purchase, which starts a new batch round
    val blockingPurchase = todayPurchase?.takeUnless { p ->
        p.storeId == storeId && (store?.batchRound ?: 1) > p.batchRoundAtPurchase
    }

    Scaffold { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize(), contentAlignment = Alignment.TopCenter) {
        Column(
            modifier = Modifier.fillMaxWidth().widthIn(max = 480.dp).padding(20.dp).verticalScroll(rememberScrollState())
        ) {
            ScreenHeader(title = t("purchase_title"))
            Spacer(modifier = Modifier.height(4.dp))
            Text(store?.name ?: "", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(24.dp))

            val blocker = blockingPurchase
            if (blocker != null) {
                AppCard {
                    Text(t("daily_limit_reached"), style = MaterialTheme.typography.titleMedium)
                }
                Spacer(modifier = Modifier.height(24.dp))
                PrimaryButton(text = t("view_order"), onClick = { onNavigateToConfirmation(blocker.id) })
            } else {
                AppCard {
                    BigStatDisplay(label = t("balance_label"), value = "${user?.balance ?: 0} شيكل")
                    Spacer(modifier = Modifier.height(12.dp))
                    BigStatDisplay(label = t("price_label"), value = "$BREAD_PRICE_ILS شيكل")
                }

                error?.let {
                    Spacer(modifier = Modifier.height(16.dp))
                    StatusChip(text = it, tone = StatusTone.DANGER)
                }

                Spacer(modifier = Modifier.height(32.dp))
                PrimaryButton(
                    text = t("pay_button"),
                    enabled = checkedExisting,
                    loading = isPaying,
                    onClick = {
                        val currentStore = store
                        val currentUser = user
                        if (currentStore == null || currentUser == null || userId == null) return@PrimaryButton
                        if (currentUser.balance < BREAD_PRICE_ILS) {
                            error = t("insufficient_balance")
                            return@PrimaryButton
                        }
                        isPaying = true
                        scope.launch {
                            delay(800) // fake payment processing delay

                            // re-check right before writing — closes the race window between
                            // the on-load check above and this tap (e.g. a rapid double-tap)
                            val alreadyThere = db.purchaseDao().findLatestForUserDate(userId, date)
                            val stillBlocked = alreadyThere != null && !(alreadyThere.storeId == storeId && currentStore.batchRound > alreadyThere.batchRoundAtPurchase)
                            if (stillBlocked) {
                                isPaying = false
                                todayPurchase = alreadyThere
                                onNavigateToConfirmation(alreadyThere!!.id)
                                return@launch
                            }

                            val existingQueue = db.purchaseDao().getQueueForStore(storeId, date).first()
                            val position = existingQueue.size + 1
                            val batchNumber = ((position - 1) / currentStore.batchSize) + 1
                            val purchaseId = UUID.randomUUID().toString()

                            db.purchaseDao().insert(
                                PurchaseEntity(
                                    id = purchaseId,
                                    storeId = storeId,
                                    userId = userId,
                                    purchaseDate = date,
                                    batchNumber = batchNumber,
                                    status = "waiting",
                                    createdAt = System.currentTimeMillis(),
                                    batchRoundAtPurchase = currentStore.batchRound
                                )
                            )
                            db.userDao().updateUser(currentUser.copy(balance = currentUser.balance - BREAD_PRICE_ILS))
                            db.storeDao().updateStore(currentStore.copy(bagsRemaining = currentStore.bagsRemaining - 1))

                            isPaying = false
                            onNavigateToConfirmation(purchaseId)
                        }
                    }
                )
            }
            Spacer(modifier = Modifier.height(12.dp))
            SecondaryButton(text = t("back"), onClick = onBack)
        }
        }
    }
}
