package com.raghif.app.notify

import android.Manifest
import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.raghif.app.R
import com.raghif.app.i18n.t

private const val CHANNEL_ID = "bread_ready_channel"
private const val CHANNEL_NAME = "إشعارات الخبز"

// simulates the real push (FCM/SMS) by firing a real local system notification on this
// same device — no server, no network, matches the "single device, simulate notify" demo scope.
object NotifyHelper {
    fun ensureChannel(context: Context) {
        // minSdk 26 — NotificationChannel always exists, no SDK guard needed
        val manager = context.getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH)
        manager.createNotificationChannel(channel)
    }

    fun hasPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    // returns false if it skipped firing due to missing permission — caller can warn the
    // owner instead of the demo silently "not working"
    @SuppressLint("MissingPermission") // guarded by hasPermission() above — lint can't see through the helper
    fun notifyBatchReady(context: Context, storeName: String, notificationId: Int): Boolean {
        if (!hasPermission(context)) return false
        ensureChannel(context)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_logo_mono)
            .setContentTitle(t("status_notified"))
            .setContentText("يمكنك استلام حزمة الخبز الآن من $storeName")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        NotificationManagerCompat.from(context).notify(notificationId, notification)
        return true
    }

    // reassures the buyer their payment went through, names the store, and gives the estimated ready time
    @SuppressLint("MissingPermission") // guarded by hasPermission() above — lint can't see through the helper
    fun notifyPaymentConfirmed(context: Context, storeName: String, readyTimeLabel: String, notificationId: Int): Boolean {
        if (!hasPermission(context)) return false
        ensureChannel(context)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_logo_mono)
            .setContentTitle(t("payment_notif_title"))
            .setContentText(t("payment_notif_body").format(storeName, readyTimeLabel))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        NotificationManagerCompat.from(context).notify(notificationId, notification)
        return true
    }
}
