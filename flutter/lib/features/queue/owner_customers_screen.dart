import 'package:flutter/material.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/offline_notice.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/models/customer_summary_model.dart';
import 'queue_controller.dart';

/// Screen displaying all customers who have ever purchased from this store.
class OwnerCustomersScreen extends StatelessWidget {
  const OwnerCustomersScreen({
    super.key,
    required this.controller,
    required this.storeId,
  });

  final QueueController controller;
  final dynamic storeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 26
            ? 96
            : 64,
        title: Text(Strings.customersTitle),
      ),
      body: StreamBuilder<List<CustomerSummaryModel>>(
        stream: controller.watchCustomersForStore(storeId),
        builder: (context, snapshot) {
          final customers = snapshot.data ?? [];
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: customers.length + 1,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index > 0) {
                      return _CustomerCard(
                        rank: index,
                        customer: customers[index - 1],
                      );
                    }
                    // Header slot: only state notices. The owner knows which
                    // bakery this is, so no name card.
                    if (snapshot.hasError) return const OfflineNotice();
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (customers.isEmpty) {
                      return AppCard(
                        child: Text(
                          Strings.customersEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.rank, required this.customer});

  /// 1-based position in the list, shown so the owner can refer to "customer
  /// #7" and see at a glance how many there are.
  final int rank;
  final CustomerSummaryModel customer;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.accent,
                child: Text(
                  '$rank',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      customer.phone,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Strings.lastPurchaseDate(customer.lastPurchaseDate),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusChip(
              text: Strings.totalPurchasesCount(customer.totalPurchases),
              tone: StatusTone.neutral,
            ),
          ),
        ],
      ),
    );
  }
}
