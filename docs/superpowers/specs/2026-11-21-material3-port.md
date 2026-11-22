# Material 3 port — study

Date: 2026-11-21. Branch context: `feat/guest-screen-m3`.

Guidance source: the `material-design-3-ui` skill
(github.com/skydashnet/material-design-3-ui-skill, v1.1.1): `SKILL.md` plus the
component-selection, color, typography, shape, navigation, feedback,
accessibility and anti-pattern references.

Goal set by the owner: use the stock Flutter Material 3 components. Write a
custom widget only where no stock one exists, and keep the reason next to it.

## Where the app stands

- `useMaterial3: true` is already on. Most screens already use stock widgets:
  `AppBar` (21 uses), `TextButton` (29), `OutlinedButton` (13), `SnackBar`,
  `AlertDialog`, `showModalBottomSheet`, `RefreshIndicator`, `NavigationBar`.
- The house look sits on top of M3 in three ways:
  1. **A partial colour scheme.** `ColorScheme.light(...)` sets about 11 roles.
     `primaryContainer`, `secondaryContainer`, `tertiary*` and the whole
     `surfaceContainer*` family fall back to defaults, and stock M3 widgets read
     exactly those roles.
  2. **Wrappers**: `PrimaryButton` (19 call sites), `SecondaryButton` (13),
     `AppCard` (35), `StatusChip` (15), `LabeledField` (10), `NumberStepper` (3),
     `AppBottomBar` (3), `BigStatDisplay` (1).
  3. **About 30 hand-built `BoxDecoration` containers** in screens: banners,
     tinted icon boxes, a login card with a shadow, and receipt panels. Screens
     also hold about 177 raw `Color(...)`/`Colors.*` literals and 200 direct
     `AppColors.*` reads instead of `Theme.of(context).colorScheme`.

## Verified in the pinned SDK (Flutter 3.47.5)

These exist in `packages/flutter/lib/src/material`: `Card.filled`,
`Card.outlined`, `FilledButton.tonal`, `IconButton.outlined`,
`IconButton.filledTonal`, `SegmentedButton`, `SearchAnchor`, `Badge`,
`MenuAnchor`, `DropdownMenu`, `CarouselView`, `NavigationBar`, `MaterialBanner`,
`DynamicSchemeVariant`, and the `surfaceContainer*` roles.

These are **not** in the SDK: button group, split button, and the M3 Expressive
loading indicator. M3 Expressive is out of scope for this port.

## Order of work

The order matters. Swapping stock components in before Phase 0 makes them
render in colours nobody picked, and in type sizes below the 15sp floor.

### Phase 0 — theme (one file: `core/theme/app_theme.dart`)

1. **Colour scheme.** Replace `ColorScheme.light(...)` with
   `ColorScheme.fromSeed(seedColor: AppColors.accent, dynamicSchemeVariant: DynamicSchemeVariant.fidelity)`.
   Then `.copyWith` the brand values that must not move:
   - `primary`: `accent`, `onPrimary`: white
   - `primaryContainer`: `accentContainer`
   - `surface`: `background` (#EEF2F6, the screen ground)
   - `surfaceContainerLowest`: white (cards and sheets). Without this override,
     fromSeed tints every surface blue.
   - `onSurface`: `textPrimary`, `onSurfaceVariant`: `textSecondary`
   - `outline`: `inputBorder`, `outlineVariant`: `border`
   - `error`, `errorContainer`, `onErrorContainer`: the existing danger set.
   Drop `scaffoldBackgroundColor`; it then follows `surface`.
2. **Success and warning.** M3 has no such roles. Add one
   `ThemeExtension<StatusColors>` that holds success, warning and neutral
   container and content pairs. `StatusChip` and the status banners read it.
   This is the one sanctioned extension.
3. **Type.** Fill all 15 `TextTheme` roles. The theme sets 10. `displaySmall`,
   `headlineLarge/Medium/Small` and `titleSmall` are missing. `AlertDialog`
   titles use `headlineSmall`. `TabBar`, chips and pickers use `titleSmall`,
   whose default is 14sp and so breaks the constitution floor (no text below
   15sp). Map each one to an existing `AppTypography` size at or above 15sp.
4. **Component themes so call sites stay bare:**
   - `filledButtonTheme`: already added on this branch (56dp pill).
   - `outlinedButtonTheme`: move `SecondaryButton`'s style here.
   - `cardTheme`: pick **one** treatment. Today it mixes a border, elevation 1
     and a custom shadow. Recommended: outlined look (`outlineVariant` border,
     elevation 0, `surfaceContainerLowest` fill), with `margin: EdgeInsets.zero`.
   - `iconButtonTheme`: 48dp minimum size.
   - `navigationBarTheme`: drop the transparent background. See Phase 2.
   - `listTileTheme`, `snackBarTheme`, `dialogTheme`, `bottomSheetTheme`: set
     fonts and shape once.
   - Delete `elevatedButtonTheme` once `PrimaryButton` moves to `FilledButton`.
5. **Shape. Decision needed.** Three scales disagree:

   | Token | UI_SPEC.md | `AppShapes` today | M3 default scale |
   |---|---|---|---|
   | small | 8 | 8 | 8 |
   | medium | 12 | 16 | 12 |
   | large | 16 | 24 | 16 |
   | extra-large | — | — | 28 |

   Recommendation: take the M3 scale (it matches UI_SPEC), so stock widgets
   need no shape overrides. Buttons stay pills (that is the M3 default too).

### Phase 1 — move the wrappers onto stock widgets (no call-site churn)

| Wrapper | Becomes | Why |
|---|---|---|
| `PrimaryButton` | Thin wrapper over `FilledButton`. Keep only the `loading` spinner, which stock buttons lack. Drop the `AnimatedScale` press effect: not M3 motion, and the ripple already gives press feedback. | One file changes 19 call sites. |
| `SecondaryButton` | Same, over `OutlinedButton`, with style from the theme. | 13 call sites. |
| `AppCard` | `Card` (theme) plus `InkWell`, as now. Margin and clip move into `cardTheme`. Where a card needs tonal weight, call sites use `Card.filled`. | 35 call sites, no API change. |
| `AppBottomBar` | Delete it. Use `NavigationBar` directly in `buyer_shell.dart` and `owner_shell.dart`. | Rounded top corners and an upward shadow are on the skill's "fake-Material" list. M3 separates the bar by its surface tone. |
| `NumberStepper` | Keep the composite. Replace `_StepperButton` with `IconButton.outlined` plus `tooltip:` (which gives the accessible name). | Flutter has no stepper. Its parts can be stock. |

Optional later: inline `FilledButton`/`OutlinedButton` at call sites and delete
both button wrappers. That is worth it only if the stock buttons gain a loading
state.

### Phase 2 — replace hand-built containers in screens

| Pattern (where) | Stock replacement |
|---|---|
| Tinted status banners (`buyer_home_screen.dart:215`, `buyer_stores_home.dart:136`) | `Card.filled(color: statusColors.warningContainer)` with a `ListTile` (leading icon, title, subtitle). For a persistent notice above a screen, `MaterialBanner`. |
| Store row with a toned border and an icon box (`buyer_stores_home.dart:337`) | `Card.outlined` plus `ListTile`. Leading: `CircleAvatar`. Trailing: `StatusChip`. |
| Tinted icon squares and circles (`buyer_home_screen.dart:282`, `wallet_verification_screen.dart:133`, `login_screen.dart:354`, `payment_success_screen.dart:37`) | `CircleAvatar(backgroundColor: primaryContainer)`. Use the ListTile `leading` slot where the box sits in a row. |
| Login form card with a custom shadow (`login_screen.dart:377`) | `Card` from the theme, or no container at all. One form on a plain surface reads fine in M3. |
| Owner history rows with `InkWell` (`owner_history_screen.dart:339`) | `ListTile(onTap:)` plus `Divider`. |
| Grey info panel inside a card (`buyer_home_screen.dart:312`, `store_details_screen.dart:316`) | `Card.filled` (`surfaceContainerHighest`). Better: drop the panel and use spacing, since the skill warns against nested cards. |
| Phone pill (`payment_otp_screen.dart:119`) | `Chip` (display only) or plain `Text` with `labelLarge`. |
| Result circles in the scanner (`qr_scanner_screen.dart:374`, `:469`) | `CircleAvatar(radius: 52)` with the status colours. |
| Language toggle on login (UI_SPEC "language toggle chip") | `SegmentedButton<Locale>` if both languages show at once. Otherwise `TextButton.icon`. Chips are for filtering, not actions. |
| Raw `AppColors.*` in screens | `Theme.of(context).colorScheme.*` or `StatusColors`. Leave `AppColors` only inside `app_theme.dart`. |

### Kept custom on purpose

| Widget | Reason |
|---|---|
| `LabeledField` | M3's floating label shrinks to 75%, under the 15sp floor. This is a documented departure; the skill allows one when it is explained. |
| `StatusChip` | M3 has no non-interactive status tag. `Chip` reads as tappable, and `Badge` is for counts. Restyle it from `StatusColors` and keep icon plus text (never colour alone). |
| `BigStatDisplay` | Two `Text`s using `displayLarge`. It is already stock in all but name. |
| Onboarding page dots | UI_SPEC makes them tappable with 48dp targets. `TabPageSelector` is not tappable. |
| QR scanner frame, receipt notches | Camera overlay and ticket artwork. Not controls. |

## Accessibility checks per phase (skill: release requirement)

- 48×48dp targets with an 8dp gap. Stock `IconButton` targets are 40dp unless
  `iconButtonTheme` sets the minimum size.
- No text below 15sp. Test with large font scale, and in RTL at 360×800 in the
  web viewport.
- Every icon-only button has a `tooltip`.
- Status is never colour alone (icon plus label).
- Contrast: re-check the `fromSeed` roles you did not override, against 4.5:1
  for text.

## Tests affected

- `test/features/queue/store_details_screen_test.dart:117`:
  `find.byType(PrimaryButton)`. Still passes in Phase 1; breaks if the wrapper
  is deleted later.
- `test/features/queue/owner_dashboard_screen_test.dart:282`:
  `find.byType(OutlinedButton)`. Still passes.
- `test/support/finders.dart:7`: `find.byType(LabeledField)`. Unchanged.

## Out of scope

- Dark theme (UI_SPEC defers it). After Phase 0 it becomes cheap, since
  `fromSeed(brightness: Brightness.dark)` produces a full scheme.
- M3 Expressive (not in the SDK).
- Adaptive layouts: the app is phone-only.
