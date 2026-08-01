package com.hassan.breadproto.ui.screens

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
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.hassan.breadproto.data.AppDatabase
import com.hassan.breadproto.i18n.t
import com.hassan.breadproto.session.Session
import com.hassan.breadproto.ui.components.AppCard
import com.hassan.breadproto.ui.components.PrimaryButton
import com.hassan.breadproto.ui.components.StatusChip
import com.hassan.breadproto.ui.components.StatusTone
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
    var pin by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var isLoggingIn by remember { mutableStateOf(false) }

    Scaffold { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(
            modifier = Modifier.fillMaxWidth().widthIn(max = 480.dp).padding(24.dp).verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(32.dp))
            Text(t("app_title"), style = MaterialTheme.typography.displayMedium, textAlign = TextAlign.Center)
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                t("app_subtitle"),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
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
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                modifier = Modifier.fillMaxWidth()
            )

            error?.let {
                Spacer(modifier = Modifier.height(16.dp))
                StatusChip(text = it, tone = StatusTone.DANGER)
            }

            Spacer(modifier = Modifier.height(24.dp))
            PrimaryButton(
                text = t("login_button"),
                loading = isLoggingIn,
                onClick = {
                    isLoggingIn = true
                    scope.launch {
                        val user = db.userDao().findByPhoneAndPin(phone.trim(), pin.trim())
                        isLoggingIn = false
                        if (user == null) {
                            error = t("login_error")
                        } else {
                            Session.currentUserId = user.id
                            error = null
                            if (user.role == "owner") onNavigateToOwnerDashboard() else onNavigateToStoreList()
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
