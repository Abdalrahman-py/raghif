package com.hassan.breadproto.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColors = lightColorScheme(
    primary = DeepBlue,
    onPrimary = Surface,
    secondary = SecondaryFill,
    onSecondary = Surface,
    background = Paper,
    onBackground = Ink,
    surface = Surface,
    onSurface = Ink,
    onSurfaceVariant = InkMuted,
    outline = OutlineGray,
    error = Danger,
    onError = DangerOn,
    errorContainer = DangerContainer
)

private val DarkColors = darkColorScheme(
    primary = DeepBlueDark,
    onPrimary = Ink,
    secondary = SecondaryFillDark,
    onSecondary = InkDark,
    background = PaperDark,
    onBackground = InkDark,
    surface = SurfaceDark,
    onSurface = InkDark,
    onSurfaceVariant = OutlineGray,
    outline = OutlineGray,
    error = Danger,
    onError = DangerOn,
    errorContainer = DangerContainer
)

// no dynamic/Material-You color here on purpose — this app needs a consistent,
// deliberately high-contrast palette regardless of the device's wallpaper theme.
// light theme first — defaults to light regardless of system setting (demo requirement)
@Composable
fun HassansBreadTheme(
    darkTheme: Boolean = false,
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        typography = Typography,
        shapes = Shapes,
        content = content
    )
}
