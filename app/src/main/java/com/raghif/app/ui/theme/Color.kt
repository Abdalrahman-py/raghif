package com.raghif.app.ui.theme

import androidx.compose.ui.graphics.Color

// Civic/accessible palette per UI_SPEC.md — WCAG AAA, high-contrast, sunlight-readable.
// Chosen for cheap/older phones, outdoor market use, low-literacy/older users, no formal
// training. No warm accent, no dynamic/Material-You color — one trustworthy CTA blue,
// near-black text, semantic status colors always paired with icon/label (never color alone).

val Navy = Color(0xFF0F172A) // header/nav chrome, owner-mode surfaces
val Slate = Color(0xFF334155) // secondary text on light bg, dividers

val Accent = Color(0xFF0369A1) // CTA — buy button, notify next batch, primary actions
val AccentPressed = Color(0xFF075985)

val Success = Color(0xFF15803D)
val Warning = Color(0xFFB45309)
val Danger = Color(0xFFB91C1C)
val StatusOn = Color(0xFFFFFFFF)

val Background = Color(0xFFF8FAFC)
val Surface = Color(0xFFFFFFFF)
val OnPrimary = Color(0xFFF8FAFC)
val OnAccent = Color(0xFFFFFFFF)

val TextPrimary = Color(0xFF020617) // 16.8:1 on Background
val TextSecondary = Color(0xFF334155) // 7.5:1 min on Background
val Border = Color(0xFFCBD5E1)

val SuccessContainer = Color(0xFFDCFCE7)
val WarningContainer = Color(0xFFFEF3C7)
val DangerContainer = Color(0xFFFEE2E2)
