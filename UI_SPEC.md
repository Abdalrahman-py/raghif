# UI Spec — Visual Design System (v2, decided)

## Problem

Current build (`app/`) has real logic wired to Room — login, purchase, countdown, notify,
mark-received all work — but every screen is stock Material3 defaults. No color identity,
no type scale, no shape system, plain `Button`/`Card`/`Scaffold`.

## Direction — decided: B, Clean Humanitarian-Utility

Ran the three original candidates (A warm-artisan, B accessibility-first, C fintech) through
`ui-ux-pro-max` against the actual deployment constraint: older/cheap Android phones, outdoor
sunlight, low-literacy and older users, bilingual AR/EN, no formal training beyond on-site
pilot. Tool match for that constraint set was unambiguous: **Accessible & Ethical** style —
WCAG AAA, high contrast, 16px+ text, 44×44 min touch targets, built for exactly this "large,
non-technical audience, public/legal-adjacent" case. Taking tool's raw civic palette as-is —
navy/slate, cold blue CTA — no warm accent mixed in.

**Rejected:** A (warm-artisan) — decorative warmth costs contrast budget for no functional gain.
C (fintech/motion-forward) — wrong signal for a subsistence-goods queue, and motion-forward
conflicts with low-end-device performance.

## Design Tokens

### Color

| Token | Hex | Use |
|---|---|---|
| `primary` | `#0F172A` | Headers, nav bar, owner-mode chrome |
| `primaryVariant` | `#334155` | Secondary text on light bg, dividers |
| `accent` (CTA) | `#0369A1` | Buy button, Notify Next Batch, primary actions |
| `accentPressed` | `#075985` | Pressed/active state of accent |
| `success` | `#15803D` | Notified/collected status, "available" state |
| `warning` | `#B45309` | Waiting/pending batch status |
| `error` | `#B91C1C` | Sold out, PIN error, form validation |
| `background` | `#F8FAFC` | Screen background |
| `surface` | `#FFFFFF` | Cards, sheets |
| `onPrimary` | `#F8FAFC` | Text/icons on `primary` |
| `onAccent` | `#FFFFFF` | Text/icons on `accent` |
| `textPrimary` | `#020617` | Body text — 16.8:1 on `background` |
| `textSecondary` | `#334155` | Meta text (timestamps, IDs) — 7.5:1 min |
| `border` | `#CBD5E1` | Card/input borders — never rely on color alone for status |

Every status (available/sold-out/notified/waiting) pairs a color with an icon or text label —
color is never the only signal (colorblind + grayscale-screen-in-sunlight safe).

Dark mode: not in scope for pilot (target devices are cheap, often locked to light system theme).
Revisit if OwnerDashboard is used at night — flag as follow-up, don't build now.

### Typography

Atkinson Hyperlegible (Latin/EN) has no Arabic coverage, so bilingual pairing is:

| Token | Font | Size | Weight | Use |
|---|---|---|---|---|
| `displayLarge` | Noto Sans / Noto Sans Arabic | 28sp | Bold | Confirmation screen bread-ready state |
| `titleLarge` | Noto Sans / Noto Sans Arabic | 22sp | SemiBold | Screen titles, store names |
| `titleMedium` | Noto Sans / Noto Sans Arabic | 18sp | SemiBold | Card headers, dashboard counters |
| `bodyLarge` | Noto Sans / Noto Sans Arabic | 17sp | Regular | Primary body text (floor is 16sp per a11y minimum; +1 for older users) |
| `bodyMedium` | Noto Sans / Noto Sans Arabic | 15sp | Regular | Secondary/meta text — never below this |
| `labelLarge` | Noto Sans / Noto Sans Arabic | 16sp | SemiBold | Button text |

Noto Sans + Noto Sans Arabic chosen over Atkinson Hyperlegible specifically because the app is
bilingual and Atkinson has no Arabic glyphs — Noto's the only pairing in the search results with
full AR+EN coverage and comparable legibility scores. `LocalLayoutDirection` flips RTL/LTR per
language toggle; icons that imply direction (back arrow, batch progress) must mirror with it.

Line height 1.5× minimum on body text. No text below `bodyMedium` (15sp) anywhere in the app.

### Shape & Spacing

8dp grid throughout.

| Token | Value | Use |
|---|---|---|
| `shape.sm` | 8dp corner | Chips, status badges |
| `shape.md` | 12dp corner | Buttons, inputs |
| `shape.lg` | 16dp corner | Cards |
| `spacing.xs` | 4dp | Icon-to-label gap |
| `spacing.sm` | 8dp | Min gap between adjacent touch targets |
| `spacing.md` | 16dp | Standard content padding |
| `spacing.lg` | 24dp | Section separation |
| `spacing.xl` | 32dp | Screen top padding below status bar |

Touch targets: 48×48dp minimum (Material floor is 44; using 48 for older/less precise hands,
consistent with M3 default). Minimum 8dp gap between any two tappable elements — no exceptions,
including table rows in OwnerQueue.

## Per-Screen Treatment

**LoginScreen** — Phone + national ID + 4-digit PIN. PIN entry as large individual digit boxes
(48dp each, `shape.md`), not a single small text field — easier to verify at a glance, easier to
target. Language toggle chip (`shape.sm`, top-right, always visible pre-login). Error state:
red border (`error`) + inline text below field, never color-only.

**StoreListScreen** — Cards (`shape.lg`, `surface`, elevation 1dp) in single column, full-width
— no grid, no GPS/map. Each card: store name (`titleMedium`), status badge top-right
(`success`/"Available" or `error`/"Sold Out" with matching icon), whole card tappable (not just a
button inside it) since that's the primary action.

**PurchaseScreen** — Store name + price (3 ILS) as `displayLarge`-adjacent hero block. Single
prominent `accent`-colored Buy button, full width, 56dp tall (above the 48dp floor since it's
the single highest-stakes tap on the screen). No secondary actions competing for attention.

**ConfirmationScreen** — Big status statement (`displayLarge`): "Reserved" / batch state. Batch
number and store name at `titleMedium`. If waiting: plain-language countdown/status, not a raw
timer digit grid. SMS-fallback note in `bodyMedium`, `textSecondary`.

**OwnerDashboardScreen** — "Remaining: X / Y" as the single largest element on screen
(`displayLarge`, tabular numerals). Purchase-window ON/OFF as a large labeled switch, not an
icon-only toggle — must read correctly to an owner glancing quickly mid-crowd. Batch size input:
stepper (+/− buttons ≥48dp) over free-text entry, fewer input errors.

**OwnerQueueScreen** — Table rows, one buyer per row, 56dp row height (taller than the 48dp
floor — dense list, needs the extra tap-accuracy margin). Batch grouping via section headers, not
just background-color banding (color-only grouping fails the "never color alone" rule). Notified
rows: `success` badge + checkmark icon. "Notify Next Batch" button: `accent`, sticky at bottom,
only rendered when unnotified buyers exist — don't disable-and-show, remove it, so there's
nothing to misread as available when it isn't.

## Process (unchanged from v1)

Reuse as-is: screen list, nav graph, screen purpose/content, all Room/DAO/payment/notify/countdown
logic. Replace only `ui/theme/Theme.kt`, `Color.kt`, `Type.kt`, `Shape.kt` and the Composables in
`ui/components/Components.kt` + each screen file to consume the new tokens instead of stock M3
defaults. Static/hardcoded data stays out of scope for this pass — presentation only.

## Accessibility Checklist (Compose-specific)

- `Modifier.semantics` / `contentDescription` on every icon-only element (status badges, stepper
  buttons)
- Theme colors sourced from `MaterialTheme.colorScheme`, never hardcoded hex in a Composable
  body
- Text styles from `MaterialTheme.typography`, never inline `fontSize=`
- `rememberSaveable` for anything that must survive rotation (PIN entry progress, batch-size
  stepper value) — plain `remember` loses it
- Stateless screen Composables — state hoisted to nav-level ViewModels, not local `mutableStateOf`
  for business data (Room results, purchase status)
