package com.raghif.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.core.content.ContextCompat
import com.raghif.app.data.AppDatabase
import com.raghif.app.ui.nav.AppNavGraph
import com.raghif.app.ui.theme.RaghifTheme
import kotlinx.coroutines.runBlocking

class MainActivity : ComponentActivity() {
    private val requestNotificationPermission =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { /* no-op either way, demo works without it too */ }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            requestNotificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
        // ponytail: runBlocking for a handful of inserts (single-digit ms) — simplest way
        // to guarantee seed data exists before any screen can query for it.
        val db = AppDatabase.getDatabase(applicationContext)
        runBlocking { AppDatabase.ensureSeeded(db) }
        setContent {
            // forced RTL regardless of device locale — this app is Arabic-only
            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
                RaghifTheme {
                    Surface(
                        modifier = Modifier.fillMaxSize(),
                        color = MaterialTheme.colorScheme.background
                    ) {
                        AppNavGraph()
                    }
                }
            }
        }
    }
}
