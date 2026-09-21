import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/models/purchase_model.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/demo_accounts.dart';
import 'confirmation_screen.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';
import 'store_list_screen.dart';

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
  });

  final QueueController controller;
  final DemoUser currentUser;

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  late final Future<PurchaseModel?> _initialOrder;

  @override
  void initState() {
    super.initState();
    _initialOrder = widget.controller.blockingPurchaseFor(
      widget.currentUser.id,
      null,
      todayDateString(),
    );
  }

  void _openStoreList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoreListScreen(
          controller: widget.controller,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.buyerHomeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: Strings.logout,
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequestedEvent()),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: FutureBuilder<PurchaseModel?>(
              future: _initialOrder,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final purchase = snapshot.data;
                if (purchase == null) {
                  return _NoOrderView(onBrowse: _openStoreList);
                }
                return _CurrentOrderView(
                  controller: widget.controller,
                  purchaseId: purchase.id,
                  onBrowse: _openStoreList,
                  onShowReceipt: () => _openReceipt(purchase.id),
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
  const _NoOrderView({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
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
          PrimaryButton(
            text: Strings.browseStoresButton,
            onPressed: onBrowse,
          ),
        ],
      ),
    );
  }
}

/// Live view of today's order: it re-reads the purchase by id, so the status
/// updates by itself when the owner calls the batch or hands the bag over.
class _CurrentOrderView extends StatelessWidget {
  const _CurrentOrderView({
    required this.controller,
    required this.purchaseId,
    required this.onBrowse,
    required this.onShowReceipt,
  });

  final QueueController controller;
  final int purchaseId;
  final VoidCallback onBrowse;
  final VoidCallback onShowReceipt;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PurchaseModel?>(
      stream: controller.watchPurchase(purchaseId),
      builder: (context, snapshot) {
        final purchase = snapshot.data;
        if (purchase == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final textTheme = Theme.of(context).textTheme;
        final (label, tone) = switch (purchase.status) {
          PurchaseStatus.waiting => (
            Strings.statusWaiting,
            StatusTone.warning,
          ),
          PurchaseStatus.notified => (
            Strings.statusNotified,
            StatusTone.success,
          ),
          PurchaseStatus.collected => (
            Strings.statusCollectedShort,
            StatusTone.neutral,
          ),
        };

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    purchase.storeName ?? '',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      StatusChip(text: label, tone: tone),
                      StatusChip(
                        text: Strings.paidBadge,
                        tone: StatusTone.success,
                      ),
                      StatusChip(
                        text: Strings.buyerHomeBatch(purchase.batchNumber),
                        tone: StatusTone.neutral,
                      ),
                    ],
                  ),
                  if (purchase.status == PurchaseStatus.notified) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      Strings.batchReadyNotificationBody,
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              text: Strings.showReceiptButton,
              onPressed: onShowReceipt,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              text: Strings.browseStoresButton,
              onPressed: onBrowse,
            ),
          ],
        );
      },
    );
  }
}
