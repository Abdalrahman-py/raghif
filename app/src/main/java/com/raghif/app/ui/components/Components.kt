package com.raghif.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DrawerState
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.Text
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.raghif.app.ui.theme.Border
import com.raghif.app.ui.theme.Danger
import com.raghif.app.ui.theme.DangerContainer
import com.raghif.app.ui.theme.RaghifTheme
import com.raghif.app.ui.theme.Spacing
import com.raghif.app.ui.theme.Success
import com.raghif.app.ui.theme.SuccessContainer
import com.raghif.app.ui.theme.Warning
import com.raghif.app.ui.theme.WarningContainer

enum class StatusTone { SUCCESS, WARNING, DANGER, NEUTRAL }

private data class ToneColors(val container: androidx.compose.ui.graphics.Color, val content: androidx.compose.ui.graphics.Color)

@Composable
private fun toneColors(tone: StatusTone): ToneColors = when (tone) {
    StatusTone.SUCCESS -> ToneColors(SuccessContainer, Success)
    StatusTone.WARNING -> ToneColors(WarningContainer, Warning)
    StatusTone.DANGER -> ToneColors(DangerContainer, Danger)
    StatusTone.NEUTRAL -> ToneColors(MaterialTheme.colorScheme.surfaceVariant, MaterialTheme.colorScheme.onSurfaceVariant)
}

@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    loading: Boolean = false
) {
    Button(
        onClick = onClick,
        enabled = enabled && !loading,
        modifier = modifier.fillMaxWidth().height(56.dp),
        shape = MaterialTheme.shapes.medium,
        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
    ) {
        if (loading) {
            CircularProgressIndicator(color = MaterialTheme.colorScheme.onPrimary, modifier = Modifier.height(24.dp).width(24.dp))
        } else {
            Text(text, style = MaterialTheme.typography.labelLarge)
        }
    }
}

// Outlined, not filled — a solid second button competes visually with the screen's one
@Composable
fun SecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.fillMaxWidth().height(56.dp),
        shape = MaterialTheme.shapes.medium,
        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary)
    ) {
        Text(text, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSecondary)
    }
}

@Composable
fun StatusChip(text: String, tone: StatusTone, modifier: Modifier = Modifier) {
    val colors = toneColors(tone)
    val icon: ImageVector = when (tone) {
        StatusTone.SUCCESS -> Icons.Filled.CheckCircle
        StatusTone.DANGER -> Icons.Filled.Error
        else -> Icons.Filled.Info
    }
    Row(
        modifier = modifier
            .background(colors.container, MaterialTheme.shapes.small)
            .padding(horizontal = 12.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = colors.content, modifier = Modifier.height(16.dp).width(16.dp))
        Spacer(modifier = Modifier.width(6.dp))
        Text(text, style = MaterialTheme.typography.labelMedium, color = colors.content)
    }
}

@Composable
fun AppCard(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.large,
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = BorderStroke(1.dp, Border),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(Spacing.md)) {
            content()
        }
    }
}

@Composable
fun ScreenHeader(
    title: String,
    modifier: Modifier = Modifier,
    actions: @Composable RowScope.() -> Unit = {}
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(title, style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.onBackground)
        Row(verticalAlignment = Alignment.CenterVertically, content = actions)
    }
}

@Composable
fun BigStatDisplay(label: String, value: String, modifier: Modifier = Modifier) {
    Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.displayMedium, color = MaterialTheme.colorScheme.onBackground)
    }
}

// --- Right-side drawer (the app is forced RTL, so ModalNavigationDrawer opens from the right) ---

@Composable
fun RaghifDrawer(
    drawerState: DrawerState,
    header: @Composable () -> Unit,
    items: @Composable ColumnScope.() -> Unit,
    content: @Composable () -> Unit
) {
    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            ModalDrawerSheet(modifier = Modifier.width(300.dp)) {
                Spacer(modifier = Modifier.height(Spacing.lg))
                Column(modifier = Modifier.padding(horizontal = Spacing.md)) { header() }
                Spacer(modifier = Modifier.height(Spacing.lg))
                Column(modifier = Modifier.padding(horizontal = Spacing.sm), content = items)
            }
        }
    ) {
        content()
    }
}

@Composable
fun DrawerStat(icon: ImageVector, text: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.md, vertical = Spacing.sm),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(modifier = Modifier.width(Spacing.xs))
        Text(text, style = MaterialTheme.typography.bodyLarge)
    }
}

@Composable
fun DrawerItem(icon: ImageVector, text: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = Spacing.md, vertical = Spacing.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(modifier = Modifier.width(Spacing.xs))
        Text(text, style = MaterialTheme.typography.bodyLarge)
    }
}

// +/- stepper over free-text entry — fewer input errors for numeric fields an owner
// edits mid-crowd (UI_SPEC.md OwnerDashboardScreen treatment).
@Composable
fun Stepper(
    value: Int,
    onValueChange: (Int) -> Unit,
    decrementDescription: String,
    incrementDescription: String,
    modifier: Modifier = Modifier,
    min: Int = 0
) {
    Row(modifier = modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
        StepperIconButton(icon = Icons.Filled.Remove, contentDescription = decrementDescription, onClick = { if (value > min) onValueChange(value - 1) })
        Text(
            value.toString(),
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center,
            modifier = Modifier.widthIn(min = 40.dp)
        )
        StepperIconButton(icon = Icons.Filled.Add, contentDescription = incrementDescription, onClick = { onValueChange(value + 1) })
    }
}

@Composable
private fun StepperIconButton(icon: ImageVector, contentDescription: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(48.dp)
            .background(MaterialTheme.colorScheme.surface, MaterialTheme.shapes.medium)
            .border(1.dp, MaterialTheme.colorScheme.outline, MaterialTheme.shapes.medium)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, contentDescription = contentDescription, tint = MaterialTheme.colorScheme.primary)
    }
}

@Preview(showBackground = true)
@Composable
private fun PrimaryButtonPreview() {
    RaghifTheme { Column(Modifier.padding(16.dp)) { PrimaryButton(text = "ادفع 3 شيكل", onClick = {}) } }
}

@Preview(showBackground = true)
@Composable
private fun SecondaryButtonPreview() {
    RaghifTheme { Column(Modifier.padding(16.dp)) { SecondaryButton(text = "رجوع", onClick = {}) } }
}

@Preview(showBackground = true)
@Composable
private fun StatusChipPreview() {
    RaghifTheme {
        Column(Modifier.padding(16.dp)) {
            StatusChip(text = "متوفر", tone = StatusTone.SUCCESS)
            Spacer(modifier = Modifier.height(8.dp))
            StatusChip(text = "قيد الانتظار", tone = StatusTone.WARNING)
            Spacer(modifier = Modifier.height(8.dp))
            StatusChip(text = "نفدت الكمية", tone = StatusTone.DANGER)
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun AppCardPreview() {
    RaghifTheme {
        Column(Modifier.padding(16.dp)) {
            AppCard { Text("مخبز الرمال", style = MaterialTheme.typography.titleMedium) }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun ScreenHeaderPreview() {
    RaghifTheme { Column(Modifier.padding(16.dp)) { ScreenHeader(title = "المخابز المتاحة") } }
}

@Preview(showBackground = true)
@Composable
private fun BigStatDisplayPreview() {
    RaghifTheme { Column(Modifier.padding(16.dp)) { BigStatDisplay(label = "المتبقي", value = "45 / 300") } }
}

@Preview(showBackground = true)
@Composable
private fun StepperPreview() {
    RaghifTheme {
        Column(Modifier.padding(16.dp)) {
            Stepper(value = 20, onValueChange = {}, decrementDescription = "إنقاص", incrementDescription = "زيادة")
        }
    }
}
