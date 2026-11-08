import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/number_stepper.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/models/store_model.dart';
import '../../domain/models/store_day_summary.dart';
import 'owner_history_screen.dart' show weekdayNameFor;
import 'owner_queue_screen.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';
import 'write_guard.dart';
import 'confirm_action.dart';
import '../account/account_screen.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/demo_accounts.dart';
import '../navigation/inbox_navigation.dart';
import '../../core/di/injection.dart';
import '../../domain/repositories/notification_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({
    super.key,
    required this.controller,
    required this.storeId,
  });

  static const routeName = 'ownerDashboard';

  final QueueController controller;
  final String storeId;

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  /// Edits in progress. The `_saved*` mirror is what those fields were at
  /// load/last save, so "is there anything to save?" is a comparison with the
  /// fields instead of a bool a tap can desync from them.
  int _allocation = 0;
  String? _openTime;
  String? _closeTime;
  int _savedAllocation = 0;
  String? _savedOpenTime;
  String? _savedCloseTime;
  bool _settingsLoaded = false;

  /// True while the allocation write is in flight; blocks repeat taps.
  bool _saving = false;

  /// True while an open/close write is in flight.
  bool _togglingOpen = false;

  @override
  void initState() {
    super.initState();
    // Controller-owned subscription for the live "بانتظار الاستلام" count.
    widget.controller.watchTodayQueueFor(widget.storeId);
  }

  /// Seeds the edit fields from the store once, when real store data first
  /// arrives — gated on `storesLoaded`, not `storeById != null`, which is
  /// already non-null from the placeholder store before the first emission.
  void _loadSettings(StoreModel store) {
    _allocation = store.dailyBagLimit;
    _openTime = store.openTime;
    _closeTime = store.closeTime;
    _savedAllocation = _allocation;
    _savedOpenTime = _openTime;
    _savedCloseTime = _closeTime;
    _settingsLoaded = true;
  }

  bool get _isDirty =>
      _allocation != _savedAllocation ||
      _openTime != _savedOpenTime ||
      _closeTime != _savedCloseTime;

  /// A window that ends before it starts would be published to buyers as an
  /// impossible range, so saving is blocked until it's corrected.
  bool get _windowInverted =>
      _openTime != null &&
      _closeTime != null &&
      _closeTime!.compareTo(_openTime!) <= 0;

  Future<void> _pickTime({required bool isOpenTime}) async {
    final current = isOpenTime ? _openTime : _closeTime;
    final initial = current != null
        ? TimeOfDay(
            hour: int.parse(current.split(':')[0]),
            minute: int.parse(current.split(':')[1]),
          )
        : TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isOpenTime) {
        _openTime = formatted;
      } else {
        _closeTime = formatted;
      }
    });
  }

  /// Opening is immediate; closing asks first, since it stops every buyer
  /// and the switch is a whole-card tap target.
  Future<void> _setStoreOpen(bool open) async {
    if (_togglingOpen) return;
    if (!open) {
      final confirmed = await confirmAction(
        context,
        title: Strings.closeStoreConfirmTitle,
        body: Strings.closeStoreConfirmBody,
        confirmLabel: Strings.closeStoreConfirmAction,
      );
      if (!confirmed || !mounted) return;
      // The dialog is modal, so a second tap can't arrive while it is up; the
      // guard only has to cover the write itself.
      if (_togglingOpen) return;
    }
    setState(() => _togglingOpen = true);
    try {
      await guardWrite(
        context,
        () => widget.controller.setStoreOpen(widget.storeId, open),
      );
    } finally {
      if (mounted) setState(() => _togglingOpen = false);
    }
  }

  Future<void> _save(StoreModel store) async {
    if (_saving) return;
    setState(() => _saving = true);
    final bool saved;
    try {
      saved = await guardWrite(
        context,
        () => widget.controller.saveAllocation(
          widget.storeId,
          dailyBagLimit: _allocation,
          batchSize: store.batchSize,
          today: todayDateString(),
          openTime: _openTime,
          closeTime: _closeTime,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    // Unsaved stays dirty, so the save button is still there to retry.
    if (!saved || !mounted) return;
    setState(() {
      _savedAllocation = _allocation;
      _savedOpenTime = _openTime;
      _savedCloseTime = _closeTime;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(Strings.savedSettingsSnack)));
  }

  void _push(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => Row(
            children: [
              // The profile button sits where the bakery logo used to: the
              // owner knows which bakery this is, but needs a way to the
              // account (which also holds sign-out).
              Semantics(
                button: true,
                label: 'حسابي',
                child: Tooltip(
                  message: 'حسابي',
                  child: InkResponse(
                    radius: 28,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AccountScreen()),
                    ),
                    // 48dp tap target around the 40dp avatar.
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.controller.storeById(widget.storeId)?.name ??
                      Strings.ownerDashboardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'الإشعارات',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              final state = context.read<AuthBloc>().state;
              if (state is! Authenticated) return;
              final u = state.user;
              openInbox(
                context,
                widget.controller,
                DemoUser(
                  id: u.id,
                  phone: u.phone,
                  pin: '',
                  role: u.role,
                  name: u.name,
                ),
                sl.isRegistered<NotificationRepository>()
                    ? sl<NotificationRepository>()
                    : null,
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final store = widget.controller.storeById(widget.storeId);
          if (!_settingsLoaded &&
              widget.controller.storesLoaded &&
              store != null) {
            _loadSettings(store);
          }
          return Column(
            children: [
              Expanded(
                // The scroll area keeps the top inset; the bar below owns the
                // bottom one so its surface reaches the screen edge.
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: RefreshIndicator(
                        onRefresh: widget.controller.refreshAll,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                Strings.ownerDashboardTitle,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'نظرة عامة على متجرك',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _DailyStats(
                                remaining: store?.bagsRemaining ?? 0,
                                allocation: store?.dailyBagLimit ?? 0,
                                pendingPickup: pendingPickupCount(
                                  widget.controller.todayQueue,
                                ),
                              ),
                              _StockStatus(store: store),
                              if (store != null)
                                Builder(
                                  builder: (context) {
                                    final suggestion = suggestNextBatch(
                                      widget.controller.todayQueue,
                                      batchSize: store.batchSize,
                                    );
                                    if (suggestion == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.md,
                                      ),
                                      child: _NextBatchCard(
                                        suggestion: suggestion,
                                        onOpen: () => _push(
                                          OwnerQueueScreen(
                                            controller: widget.controller,
                                            storeId: widget.storeId,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: AppSpacing.md),
                              _WeeklyStatsCard(
                                load: () =>
                                    widget.controller.dailySummariesForStore(
                                      widget.storeId,
                                      limit: 7,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _StoreOpenCard(
                                isOpen: store?.isOpen ?? false,
                                busy: _togglingOpen,
                                onChanged: (value) {
                                  // A gate change deserves tactile confirmation:
                                  // the owner's eyes are on the queue, not the
                                  // switch.
                                  HapticFeedback.selectionClick();
                                  _setStoreOpen(value);
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _SettingsCard(
                                isDirty: _isDirty,
                                saving: _saving,
                                windowInverted: _windowInverted,
                                allocation: _allocation,
                                openTime: _openTime,
                                closeTime: _closeTime,
                                onAllocationChanged: (value) =>
                                    setState(() => _allocation = value),
                                onPickOpenTime: () =>
                                    _pickTime(isOpenTime: true),
                                onPickCloseTime: () =>
                                    _pickTime(isOpenTime: false),
                                onSave: store == null
                                    ? null
                                    : () => _save(store),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // One action pinned to the bottom: the queue is where the owner
              // works. Customers/history moved into the scroll — three stacked
              // full-width buttons held ~190dp of every screen height
              // permanently for two read-only destinations.
              //
              // Surface + hairline so it reads as a bar the list scrolls under,
              // instead of a button slicing the list.
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 6,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: PrimaryButton(
                          text: Strings.goToQueue,
                          onPressed: () => _push(
                            OwnerQueueScreen(
                              controller: widget.controller,
                              storeId: widget.storeId,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DailyStats extends StatelessWidget {
  const _DailyStats({
    required this.remaining,
    required this.allocation,
    required this.pendingPickup,
  });

  final int remaining;
  final int allocation;
  final int pendingPickup;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 330 ||
            MediaQuery.textScalerOf(context).scale(15) > 19;
        final cards = [
          _SmallStat(
            icon: Icons.bakery_dining_outlined,
            value: remaining,
            label: Strings.remainingLabel,
          ),
          _SmallStat(
            icon: Icons.hourglass_top_rounded,
            value: pendingPickup,
            label: Strings.pendingPickupLabel,
          ),
          _SmallStat(
            icon: Icons.inventory_2_outlined,
            value: allocation,
            label: Strings.allocationLabel,
          ),
        ];
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                cards[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.accent,
            child: Icon(icon),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$value',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, textAlign: TextAlign.center, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Out-of-stock / low-stock notice. The numbers themselves live in
/// [_DailyStats]; this only adds the sentence that says what to do about them
/// (icon + text, never color alone — UI_SPEC.md). Sold out supersedes low
/// stock: the two need different actions.
class _StockStatus extends StatelessWidget {
  const _StockStatus({required this.store});

  final StoreModel? store;

  @override
  Widget build(BuildContext context) {
    final remaining = store?.bagsRemaining ?? 0;
    final Widget chip;
    if (remaining <= 0) {
      chip = const StatusChip(
        text: Strings.outOfStockNotice,
        tone: StatusTone.danger,
      );
    } else if (store != null && isLowStock(store!)) {
      chip = StatusChip(
        text: Strings.lowStockWarning(remaining),
        tone: StatusTone.warning,
        icon: Icons.warning_amber_rounded,
      );
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Align(alignment: AlignmentDirectional.centerStart, child: chip),
    );
  }
}

/// The open/closed gate the spec asked for as a labeled switch. The whole row
/// is the tap target; the switch writes immediately (a gate, not a setting to
/// remember to save) and buyer-side `canPurchase` reads the same flag.
class _StoreOpenCard extends StatelessWidget {
  const _StoreOpenCard({
    required this.isOpen,
    required this.busy,
    required this.onChanged,
  });

  final bool isOpen;

  /// A write is in flight: the card ignores taps and shows a spinner.
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: busy ? null : () => onChanged(!isOpen),
      child: Semantics(
        label: Strings.storeOpenSwitchLabel,
        toggled: isOpen,
        button: true,
        // One node — without this, the row, the label and the switch each
        // announce themselves.
        excludeSemantics: true,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusChip(
                    text: isOpen ? 'الحجز مفتوح' : Strings.storeClosedBadge,
                    tone: isOpen ? StatusTone.success : StatusTone.neutral,
                    icon: isOpen
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    Strings.storeOpenSwitchLabel,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isOpen
                        ? Strings.storeOpenOnHelper
                        : Strings.storeOpenOffHelper,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Switch(value: isOpen, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Today's allocation and purchase window, saved together by one action.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.isDirty,
    required this.saving,
    required this.windowInverted,
    required this.allocation,
    required this.openTime,
    required this.closeTime,
    required this.onAllocationChanged,
    required this.onPickOpenTime,
    required this.onPickCloseTime,
    required this.onSave,
  });

  final bool isDirty;
  final bool saving;
  final bool windowInverted;
  final int allocation;
  final String? openTime;
  final String? closeTime;
  final ValueChanged<int> onAllocationChanged;
  final VoidCallback onPickOpenTime;
  final VoidCallback onPickCloseTime;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(Strings.todaySettingsTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          // The label and its stepper share one row, so the control sits right
          // beside the words it changes.
          Row(
            children: [
              Expanded(
                child: Text(
                  Strings.allocationLabel,
                  style: textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              NumberStepper(
                value: allocation,
                onChanged: onAllocationChanged,
                step: 10,
                decrementLabel: Strings.decreaseValue,
                incrementLabel: Strings.increaseValue,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Text(Strings.purchaseWindowHint, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _TimePickerField(
                  label: Strings.openTimeLabel,
                  time: openTime,
                  onTap: onPickOpenTime,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TimePickerField(
                  label: Strings.closeTimeLabel,
                  time: closeTime,
                  onTap: onPickCloseTime,
                ),
              ),
            ],
          ),
          if (windowInverted) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    Strings.windowOrderError,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (isDirty) ...[
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    Strings.unsavedSettingsNote,
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              text: Strings.saveTodaySettings,
              loading: saving,
              onPressed: windowInverted ? null : onSave,
            ),
          ] else
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    Strings.savedSettingsNote,
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Label above the picked time, so long Arabic labels don't wrap the value
/// onto its own line the way an inline "label: value" button did.
class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final String? time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppShapes.medium),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // bodyMedium is the app's type floor (15sp); the bodySmall that was
          // here is 12sp and comes from the platform typography, i.e. a font
          // with no Arabic glyphs.
          Text(
            label,
            style: textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(time ?? Strings.notSetLabel, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// "Call the next batch" nudge. Opens the queue; the owner confirms there.
class _NextBatchCard extends StatelessWidget {
  const _NextBatchCard({required this.suggestion, required this.onOpen});

  final NextBatchSuggestion suggestion;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onOpen,
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.accent,
            child: Icon(Icons.notifications_active_outlined),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Strings.suggestBatchTitle(suggestion.batch),
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  Strings.suggestBatchBody(suggestion.count),
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left),
        ],
      ),
    );
  }
}

/// Sales over the last seven days, from the per-day summaries.
class _WeeklyStatsCard extends StatefulWidget {
  const _WeeklyStatsCard({required this.load});

  final Future<List<StoreDaySummary>> Function() load;

  @override
  State<_WeeklyStatsCard> createState() => _WeeklyStatsCardState();
}

class _WeeklyStatsCardState extends State<_WeeklyStatsCard> {
  late final Future<List<StoreDaySummary>> _days = widget.load();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<List<StoreDaySummary>>(
      future: _days,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final stats = weeklyStats(snapshot.data!);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Strings.weeklyTitle, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (stats.sold == 0)
                Text(Strings.weeklyEmpty, style: textTheme.bodyMedium)
              else ...[
                Text(
                  Strings.weeklySold(stats.sold),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${Strings.weeklyCollected(stats.collectedPercent)} · '
                  '${Strings.weeklyAverage(stats.dailyAverage)}',
                  style: textTheme.bodyMedium,
                ),
                if (stats.cash > 0)
                  Text(
                    Strings.weeklyCash(stats.cash.toStringAsFixed(0)),
                    style: textTheme.bodyMedium,
                  ),
                if (stats.bestDate != null)
                  Text(
                    Strings.weeklyBest(
                      weekdayNameFor(stats.bestDate!),
                      stats.bestSold,
                    ),
                    style: textTheme.bodyMedium,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
