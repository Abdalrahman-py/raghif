# Material 3 port — study notes (2026-11-21)

The app already runs with `useMaterial3: true`, so this is not a framework
switch. The work is replacing hand-made widgets and theme values with the
built-in M3 ones, one screen at a time, without dropping the accessibility
floors in `constitution.md` (body ≥ 16sp, nothing under 15sp, 48dp targets,
4.5:1 contrast, 56dp primary actions for low-literacy users).

## Theme (`lib/core/theme/app_theme.dart`)

| Today | M3 target | Note |
|---|---|---|
| Hand-built `ColorScheme.light(...)` with ~10 roles | `ColorScheme.fromSeed(seedColor: AppColors.accent, ...)` with overrides for brand/status colours | Fills the roles nothing sets now: `primaryContainer`, `secondaryContainer`, `surfaceContainer*`, `outlineVariant`. Built-ins like `Card.filled`, `FilledButton.tonal`, `SearchBar`, `NavigationBar` read those roles. Re-run `test/a11y/constitution_v_test.dart` after the change. |
| `textTheme` sets 10 roles | Set all 15 (add `displaySmall`, `headlineLarge/Medium/Small`, `titleSmall`) | `headlineSmall` is used (guest screen, sheets) and currently falls back to M3 defaults outside the app's type scale. |
| `elevatedButtonTheme` as the primary button | `filledButtonTheme` (added 2026-11-21, same 56dp pill) | M3's primary action is `FilledButton`; elevated is for buttons on busy backgrounds. |
| `cardTheme` with border + shadow | Pick one: `Card.outlined` (border, no shadow) or `Card.filled` (tone step) | M3 cards at rest are flat. Needs the surfaceContainer roles above. |
| Custom `navigationBarTheme` (solid accent pill) | Default M3 `NavigationBar` indicator (`secondaryContainer`) | Optional; the current pill is a brand choice and passes contrast. |

## Custom widgets → built-ins (`lib/core/widgets/`)

| Widget | Built-in | Effort |
|---|---|---|
| `PrimaryButton` (ElevatedButton + scale animation + spinner) | `FilledButton`; loading = `FilledButton(onPressed: null, child: CircularProgressIndicator)` | Small. Used on most screens; swap file by file. |
| `SecondaryButton` | `OutlinedButton` or `FilledButton.tonal` | Small. |
| `AppCard` | `Card.outlined` / `Card.filled` + `InkWell`, or `ListTile` inside a `Card` for list rows | Medium (many uses, visual tests). |
| `OfflineNotice` | `MaterialBanner` | Small. |
| `AppBottomBar` | Already wraps `NavigationBar` | None. |
| `LabeledField` | `TextField` with `InputDecoration(labelText:)` | Keep: the label above the field is easier to read for low-literacy users than a floating label. |
| `StatusChip` | No M3 status chip (`Chip` reads as tappable) | Keep. |
| `NumberStepper` | No M3 equivalent | Keep. |
| `BigStatDisplay` | None | Keep. |

## Screen patterns

- Store rows (guest, buyer home): `ListTile` (title = name, subtitle = area and
  bags left, trailing = status) inside `Card.outlined`.
- Owner filters and day pickers: `SegmentedButton`, `FilterChip`.
- Owner queue search: `SearchBar` / `SearchAnchor`.
- Confirmations: `AlertDialog` is already M3; bottom sheets already use
  `showDragHandle`.
- Onboarding carousel: `PageView` + `TabPageSelector` (built-in page dots)
  instead of the hand-drawn dots.

## Decided on the guest screen (2026-11-21)

- One primary action (`FilledButton`, "create account"), one text action
  (sign in).
- Owners get one muted line, with only "تواصل معنا" as a link. No sentence and
  button repeating each other.
- Legal links are a muted footer line: two `TextButton`s, 16sp, 48dp, no
  accent colour. That is the pattern WhatsApp, Telegram and Google sign-in
  screens use. Not inline `TextSpan` links (tiny targets, poor screen-reader
  support).

## Open decision

The first-run carousel (3 slides) and the guest screen's "كيف يعمل رغيف؟" card
say the same thing. Keep one. Recommendation: drop the card and keep the guest
screen's store preview as the first thing people see. The card's 1/2/3
numbering is also the kind of decoration the design review flags.

## Order of work

1. Theme: `fromSeed` + full `textTheme`. Run the a11y test.
2. `PrimaryButton` → `FilledButton` across screens.
3. `AppCard` → `Card.outlined` / `ListTile`, one feature folder per PR.
4. `OfflineNotice` → `MaterialBanner`; owner search → `SearchBar`.

Each step is its own PR with before/after screenshots at 360×800.
