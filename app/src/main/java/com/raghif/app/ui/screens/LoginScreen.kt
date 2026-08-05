package com.raghif.app.ui.screens

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.Image
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.raghif.app.R
import com.raghif.app.data.AppDatabase
import com.raghif.app.data.newBuyer
import com.raghif.app.data.validateRegistration
import com.raghif.app.i18n.t
import com.raghif.app.session.Session
import com.raghif.app.ui.components.AppCard
import com.raghif.app.ui.components.PrimaryButton
import com.raghif.app.ui.components.StatusChip
import com.raghif.app.ui.components.StatusTone
import kotlinx.coroutines.launch

@Composable
fun LoginScreen(
    onNavigateToStoreList: () -> Unit,
    onNavigateToOwnerDashboard: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val db = remember { AppDatabase.getDatabase(context) }

    var phone by remember { mutableStateOf("") }
    var pin by rememberSaveable { mutableStateOf("") }
    var personalId by remember { mutableStateOf("") }
    var name by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var isLoggingIn by remember { mutableStateOf(false) }
    var isRegistering by remember { mutableStateOf(false) }

    Scaffold { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(
            modifier = Modifier.fillMaxWidth().widthIn(max = 480.dp).padding(24.dp).verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(24.dp))
            Image(
                painter = painterResource(R.drawable.ic_logo),
                contentDescription = null,
                modifier = Modifier.size(88.dp)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(t("app_title"), style = MaterialTheme.typography.displayMedium, textAlign = TextAlign.Center)
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                t("app_subtitle"),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(12.dp))
            StatusChip(text = t("demo_badge"), tone = StatusTone.NEUTRAL)
            Spacer(modifier = Modifier.height(40.dp))

            OutlinedTextField(
                value = phone,
                onValueChange = { phone = it },
                label = { Text(t("phone_label")) },
                singleLine = true,
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Phone),
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(12.dp))
            OutlinedTextField(
                value = pin,
                onValueChange = { if (it.length <= 4) pin = it },
                label = { Text(t("pin_label")) },
                singleLine = true,
                isError = error != null,
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                visualTransformation = PasswordVisualTransformation(),
                modifier = Modifier.fillMaxWidth()
            )

            if (isRegistering) {
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text(t("name_label")) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = personalId,
                    onValueChange = { personalId = it },
                    label = { Text(t("personal_id_label")) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(16.dp))
                StatusChip(text = t("new_account_notice"), tone = StatusTone.NEUTRAL)
            }

            error?.let {
                Spacer(modifier = Modifier.height(16.dp))
                StatusChip(text = it, tone = StatusTone.DANGER)
            }

            Spacer(modifier = Modifier.height(24.dp))
            PrimaryButton(
                text = if (isRegistering) t("register_button") else t("login_button"),
                loading = isLoggingIn,
                onClick = {
                    isLoggingIn = true
                    scope.launch {
                        if (isRegistering) {
                            val validationError = validateRegistration(phone, pin, personalId, name)
                            if (validationError != null) {
                                error = t(validationError)
                                isLoggingIn = false
                                return@launch
                            }
                            val newUser = newBuyer(phone, pin, personalId, name)
                            db.userDao().insertAll(listOf(newUser))
                            isLoggingIn = false
                            Session.currentUserId = newUser.id
                            error = null
                            onNavigateToStoreList()
                            return@launch
                        }

                        val user = db.userDao().findByPhoneAndPin(phone.trim(), pin.trim())
                        if (user != null) {
                            isLoggingIn = false
                            Session.currentUserId = user.id
                            error = null
                            if (user.role == "owner") onNavigateToOwnerDashboard() else onNavigateToStoreList()
                            return@launch
                        }

                        val existing = db.userDao().findByPhone(phone.trim())
                        isLoggingIn = false
                        if (existing != null) {
                            error = t("login_error")
                        } else {
                            error = null
                            isRegistering = true
                        }
                    }
                }
            )

            Spacer(modifier = Modifier.height(32.dp))
            AppCard {
                Text(t("demo_accounts_title"), style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                Text("${t("demo_buyer_label")} — ${AppDatabase.DEMO_BUYER_PHONE} / ${AppDatabase.DEMO_BUYER_PIN}", style = MaterialTheme.typography.bodyMedium)
                Text("${t("demo_owner_label")} — ${AppDatabase.DEMO_OWNER_PHONE} / ${AppDatabase.DEMO_OWNER_PIN}", style = MaterialTheme.typography.bodyMedium)
            }
        }
        }
    }
}
