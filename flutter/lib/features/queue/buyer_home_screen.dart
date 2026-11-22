import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/offline_notice.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/models/store_model.dart';
import '../auth/demo_accounts.dart';
import 'confirmation_screen.dart';
import 'payment_chip.dart';
import 'postpone_booking_screen.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';
import 'confirm_action.dart';

/// Buyer home — "my current order" (walkthrough P0 #2).
///
/// Until now the receipt QR only existed on the confirmation screen: leave it
/// without saving and the pickup ticket was gone, and there was nowhere to
/// watch the order move from waiting → ready → collected. This screen is that
/// place, and it reopens the receipt at any time.
///
/// Deliberately no ETA: a "time until next batch" would need a real owner-set
/// batch schedule (decision C removed the invented estimate), so the screen
/// shows the batch number and plain status instead.
class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({
    super.key,
    required this.controller,
    required this.currentUser,
    this.embedded = false,
  });

  final QueueController controller;
  final DemoUser currentUser;
  final bool embedded;

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  late Future<List<PurchaseModel>> _orders = _load();

  Future<List<PurchaseModel>> _load() => widget.controller.upcomingPurchases(
    widget.currentUser.id,
    todayDateString(),
  );

  void _reload() {
    final next = _load();
    setState(() {
      _orders = next;
    });
  }

  Future<void> _postpone(PurchaseModel booking) async {
    final moved = await Navigator.of(context).push<PurchaseModel>(
      MaterialPageRoute(
        builder: (_) => PostponeBookingScreen(
          controller: widget.controller,
          purchase: booking,
        ),
      ),
    );
    if (moved != null && mounted) _reload();
  }

  void _openReceipt(String purchaseId) {
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
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(Strings.buyerHomeTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: Strings.logout,
                  onPressed: () => confirmLogout(context),
                ),
              ],
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: FutureBuilder<List<PurchaseModel>>(
              future: _orders,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return OfflineNotice(onRetry: _reload);
                }
                final orders = snapshot.data ?? const <PurchaseModel>[];
                if (orders.isEmpty) {
                  return const _NoOrderView();
                }
                // Today's booking and a postponed tomorrow one are separate
                // bookings: each gets its own card and receipt.
                return RefreshIndicator(
                  onRefresh: () async {
                    await widget.controller.refreshAll();
                    _reload();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      for (final (i, order) in orders.indexed) ...[
                        if (i > 0) const SizedBox(height: 32),
                        _CurrentOrderView(
                          key: ValueKey(order.id),
                          controller: widget.controller,
                          purchaseId: order.id,
                          onShowReceipt: () => _openReceipt(order.id),
                          onPostpone: _postpone,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NoOrderView extends StatelessWidget {
  const _NoOrderView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lunch_dining_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            Strings.buyerHomeNoOrder,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            Strings.buyerHomeNoOrderHint,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Live view of today's order: it re-reads the purchase by id, so the status
/// updates by itself when the owner calls the batch or hands the bag over.
class _CurrentOrderView extends StatelessWidget {
  const _CurrentOrderView({
    super.key,
    required this.controller,
    required this.purchaseId,
    required this.onShowReceipt,
    required this.onPostpone,
  });

  final QueueController controller;
  final String purchaseId;
  final VoidCallback onShowReceipt;
  final ValueChanged<PurchaseModel> onPostpone;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PurchaseModel?>(
      stream: controller.watchPurchase(purchaseId),
      builder: (context, snapshot) {
        final purchase = snapshot.data;
        if (purchase == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final future = purchase.purchaseDate.compareTo(todayDateString()) > 0;
        final textTheme = Theme.of(context).textTheme;
        final store = controller.storeById(purchase.storeId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: purchase.status == PurchaseStatus.waiting
                    ? AppColors.warningContainer
                    : AppColors.successContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    purchase.status == PurchaseStatus.waiting
                        ? Icons.schedule_rounded
                        : Icons.check_circle_outline_rounded,
                    color: purchase.status == PurchaseStatus.waiting
                        ? AppColors.onWarningContainer
                        : AppColors.onSuccessContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      future
                          ? 'حجزك القادم بتاريخ ${purchase.purchaseDate}. انتظر إشعار المخبز في موعد الحجز.'
                          : switch (purchase.status) {
                              PurchaseStatus.waiting =>
                                Strings.waitingReassurance,
                              PurchaseStatus.notified =>
                                Strings.batchReadyNotificationBody,
                              PurchaseStatus.collected =>
                                'تم استلام طلبك، صحتين وعافية',
                            },
                      style: textTheme.bodyMedium?.copyWith(
                        color: purchase.status == PurchaseStatus.waiting
                            ? AppColors.onWarningContainer
                            : AppColors.onSuccessContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PaymentChip(
                        prepaid: purchase.isPrepaid,
                        price: store?.bagPrice ?? StoreModel.defaultBagPrice,
                      ),
                      StatusChip(
                        text: Strings.buyerHomeBatch(purchase.batchNumber),
                        tone: StatusTone.neutral,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.accentContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.storefront_outlined,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              purchase.storeName ?? store?.name ?? '',
                              style: textTheme.titleLarge,
                            ),
                            if (store != null && store.area.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(store.area, style: textTheme.bodyMedium),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Strings.receiptPurchaseIdLabel,
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text('#${purchase.id}', style: textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Text(
                          '${Strings.receiptDateLabel}: ${purchase.purchaseDate}',
                          style: textTheme.bodyMedium,
                        ),
                        if (purchase.originalPurchaseDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            Strings.postponedFrom(
                              purchase.originalPurchaseDate!,
                            ),
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: Strings.showReceiptButton,
              onPressed: onShowReceipt,
            ),
            if (purchase.purchaseDate == todayDateString() &&
                purchase.status != PurchaseStatus.collected &&
                purchase.postponementCount == 0) ...[
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'تأجيل الحجز إلى الغد',
                onPressed: () => onPostpone(purchase),
              ),
            ],
          ],
        );
      },
    );
  }
}
