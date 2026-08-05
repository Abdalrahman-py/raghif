package com.raghif.app.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.raghif.app.R

// Noto Sans Arabic — Arabic-only app (no AR/EN toggle), bundled as static weights so it
// renders correctly offline on cheap phones without a Google Fonts network fetch.
val NotoSansArabic = FontFamily(
    Font(R.font.notosansarabic_regular, FontWeight.Normal),
    Font(R.font.notosansarabic_medium, FontWeight.Medium),
    Font(R.font.notosansarabic_semibold, FontWeight.SemiBold),
    Font(R.font.notosansarabic_bold, FontWeight.Bold)
)

// Sizes per UI_SPEC.md token table — legible in sunlight, for a queue app used standing up.
// Floor is bodyMedium (15sp); nothing in the app goes below that.
val Typography = Typography(
    displayLarge = TextStyle(fontFamily = NotoSansArabic, fontWeight = FontWeight.Bold, fontSize = 28.sp, lineHeight = 42.sp),
    displayMedium = TextStyle(fontFamily = NotoSansArabic, fontWeight = FontWeight.Bold, fontSize = 24.sp, lineHeight = 36.sp),
    headlineLarge = TextStyle(fontFamily = NotoSansArabic, fontWeight = FontWeight.Bold, fontSize = 22.sp, lineHeight = 33.sp),
    headlineMedium = TextStyle(fontFamily = NotoSansArabic, fontWeight = FontWeight.Bold, fontSize = 20.sp, lineHeight = 30.sp),
    titleLarge = TextStyle(fontFamily = NotoSansArabic, fontWeight = FontWeight.SemiBold, fontSize = 22.sp, lineHeight = 33.sp),
    titleMedium = TextStyle(fontFamily = NotoSansArabic, fontWeight = FontWeight.SemiBold, fontSize = 18.sp, lineHeight = 27.sp),
    bodyLarge = TextStyle(fontFamily = NotoSansArabic, fontWeight = FontWeight.Normal, fontSize = 17.sp, lineHeight = 26.sp, letterSpacing = 0.2.sp),
    bodyMedium = TextStyle(fontFamily = NotoSansArabic, fontWeight = FontWeight.Normal, fontSize = 15.sp, lineHeight = 23.sp, letterSpacing = 0.2.sp),
    labelLarge = TextStyle(fontFamily = NotoSansArabic, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, lineHeight = 24.sp, letterSpacing = 0.3.sp), // button text
    labelMedium = TextStyle(fontFamily = NotoSansArabic, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, lineHeight = 23.sp, letterSpacing = 0.3.sp),
    labelSmall = TextStyle(fontFamily = NotoSansArabic, fontWeight = FontWeight.Medium, fontSize = 15.sp, lineHeight = 23.sp, letterSpacing = 0.3.sp)
)
