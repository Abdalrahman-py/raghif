import 'package:flutter/material.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/models/store_list_entry.dart';
import '../auth/demo_accounts.dart';
import 'confirmation_screen.dart';
import 'purchase_screen.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';
import 'store_list_logic.dart';

/// Store details — the hub the buyer lands on from the store list.
///
/// Shows who the store is, whether it can be bought from right now, this
/// buyer's own order at it today (with a way back to the receipt QR), their
/// last visit, and the pin toggle. The buy action on top of that goes to
/// [PurchaseScreen], so availability is re-checked at purchase time.
class StoreDetailsScreen extends StatefulWidget {
  const StoreDetailsScreen({
    super.key,
    required this.controller,
    required this.currentUser,
    required this.entry,
  });

  final QueueController controller;
  final DemoUser currentUser;

  /// Snapshot from the list; live values are re-read from the controller so
  /// pin toggles and stock changes show up immediately.
  final StoreListEntry entry;

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // In case the screen is opened without the list having been watched.
    widget.controller.watchStoreListFor(widget.currentUser.id);
  }

  StoreListEntry get _entry {
    for (final e in widget.controller.storeList) {
      if (e.store.id == widget.entry.store.id) return e;
    }
    return widget.entry;
  }

  void _openPurchase() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PurchaseScreen(
          controller: widget.controller,
          storeId: widget.entry.store.id,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _openReceipt(int purchaseId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(
          controller: widget.controller,
          purchaseId: purchaseId,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = todayDateString();
    return Scaffold(
      appBar: AppBar(title: Text(Strings.storeDetailsTitle)),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final entry = _entry;
          final store = entry.store;
          final available = store.isAvailable;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _IdentityCard(
                      entry: entry,
                      onTogglePin: () => widget.controller.setStorePinned(
                        widget.currentUser.id,
                        store.id,
                        !entry.pinned,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AvailabilityCard(entry: entry),
                    if (entry.hasOrderToday) ...[
                      const SizedBox(height: AppSpacing.md),
                      _MyOrderCard(
                        entry: entry,
                        onShowReceipt: entry.todayPurchaseId == null
                            ? null
                            : () => _openReceipt(entry.todayPurchaseId!),
                      ),
                    ],
                    if (entry.lastPurchaseDate != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _HistoryCard(entry: entry, today: today),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      text: Strings.reserveBagButton,
                      onPressed: available ? _openPurchase : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.entry, required this.onTogglePin});

  final StoreListEntry entry;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    final store = entry.store;
    final textTheme = Theme.of(context).textTheme;
    final available = store.isAvailable;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.storefront,
                color: available
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(store.name, style: textTheme.titleLarge),
              ),
              StatusChip(
                text: available ? Strings.available : Strings.soldOut,
                tone: available ? StatusTone.success : StatusTone.danger,
              ),
            ],
          ),
          if (store.area.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              store.area,
              style: textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onTogglePin,
              icon: Icon(
                entry.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: entry.pinned ? AppColors.accent : null,
              ),
              label: Text(
                entry.pinned ? Strings.unpinStore : Strings.pinStore,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.entry});

  final StoreListEntry entry;

  @override
  Widget build(BuildContext context) {
    final store = entry.store;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (store.isAvailable) ...[
            Text(
              Strings.bagsRemaining(store.bagsRemaining, store.dailyBagLimit),
              style: textTheme.bodyLarge,
            ),
            if (store.hasPurchaseWindow) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                Strings.purchaseWindowRange(store.openTime!, store.closeTime!),
                style: textTheme.bodyMedium,
              ),
            ],
          ] else
            Text(
              store.isOpen ? Strings.soldOut : Strings.storeClosedLabel,
              style: textTheme.bodyLarge,
            ),
        ],
      ),
    );
  }
}

class _MyOrderCard extends StatelessWidget {
  const _MyOrderCard({required this.entry, required this.onShowReceipt});

  final StoreListEntry entry;
  final VoidCallback? onShowReceipt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = entry.todayStatus!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(Strings.myOrderTodayTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              StatusChip(text: _orderLabel(status), tone: _orderTone(status)),
              const StatusChip(
                text: Strings.paidBadge,
                tone: StatusTone.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            text: Strings.showReceiptButton,
            onPressed: onShowReceipt,
          ),
        ],
      ),
    );
  }

  String _orderLabel(PurchaseStatus status) => switch (status) {
    PurchaseStatus.waiting => Strings.orderWaiting,
    PurchaseStatus.notified => Strings.orderReady,
    PurchaseStatus.collected => Strings.orderCollected,
  };

  StatusTone _orderTone(PurchaseStatus status) => switch (status) {
    PurchaseStatus.waiting => StatusTone.warning,
    PurchaseStatus.notified => StatusTone.success,
    PurchaseStatus.collected => StatusTone.neutral,
  };
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.today});

  final StoreListEntry entry;
  final String today;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Text(
        Strings.lastPurchaseFrom(
          purchaseDateLabel(entry.lastPurchaseDate!, today),
        ),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
