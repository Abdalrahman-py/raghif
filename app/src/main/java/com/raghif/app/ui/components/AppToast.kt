package com.raghif.app.ui.components

import android.content.Context
import android.os.Build
import android.view.LayoutInflater
import android.widget.TextView
import android.widget.Toast
import com.raghif.app.R

/**
 * App-branded toast. On Android 12+ the system toast already shows the app's
 * icon (our logo) next to the text, so we let the system render it natively.
 * On older versions we use a custom view with the logo baked in.
 */
fun showAppToast(context: Context, message: String, length: Int = Toast.LENGTH_LONG) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        Toast.makeText(context, message, length).show()
        return
    }
    val toast = Toast(context)
    val view = LayoutInflater.from(context).inflate(R.layout.toast_logo, null)
    view.findViewById<TextView>(R.id.toast_text).text = message
    toast.view = view
    toast.duration = length
    toast.show()
}
