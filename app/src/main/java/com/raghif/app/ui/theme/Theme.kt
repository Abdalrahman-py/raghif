package com.raghif.app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

// primary maps to Accent (not Navy) — PrimaryButton and other CTA-keyed components read
// colorScheme.primary, and the spec's single trustworthy CTA color is the accent blue.
// Navy is kept as `secondary` for chrome-adjacent uses (SecondaryButton outline/border).
private val LightColors = lightColorScheme(
    primary = Accent,
    onPrimary = OnAccent,
    secondary = Navy,
    onSecondary = OnPrimary,
    background = Background,
    onBackground = TextPrimary,
    surface = Surface,
    onSurface = TextPrimary,
    onSurfaceVariant = TextSecondary,
    outline = Border,
    error = Danger,
    onError = StatusOn,
    errorContainer = DangerContainer
)

// Dark mode intentionally out of scope for pilot — target devices are cheap, often locked
// to light system theme (UI_SPEC.md). Revisit if OwnerDashboard sees night use.
@Composable
fun RaghifTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = LightColors,
        typography = Typography,
        shapes = Shapes,
        content = content
    )
}
