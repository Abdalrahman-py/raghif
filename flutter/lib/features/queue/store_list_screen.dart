import 'package:flutter/material.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_chip.dart';
import '../auth/demo_accounts.dart';
import 'models.dart';
import 'purchase_screen.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';

/// UI_SPEC.md StoreListScreen: full-width cards, single column, no grid/map.
/// Whole card is tappable when available since that's the primary action.
class StoreListScreen extends StatelessWidget {
  const StoreListScreen({
    super.key,
    required this.controller,
    required this.currentUser,
  });

  static const routeName = 'storeList';

  final QueueController controller;
  final DemoUser currentUser;

  @override
  Widget build(BuildContext context) {
    final today = todayDateString();
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.storeListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: Strings.logout,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final stores = controller.stores;
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        0,
                      ),
                      child: Text(
                        '${Strings.todayLabel}: $today',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: stores.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Text(
                                  Strings.noStores,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              itemCount: stores.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) => _StoreRow(
                                store: stores[index],
                                onTap: stores[index].isAvailable
                                    ? () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PurchaseScreen(
                                            controller: controller,
                                            storeId: stores[index].id,
                                            currentUser: currentUser,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
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

class _StoreRow extends StatelessWidget {
  const _StoreRow({required this.store, required this.onTap});

  final Store store;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final available = store.isAvailable;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Text(
                      store.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                StatusChip(
                  text: available ? Strings.available : Strings.soldOut,
                  tone: available ? StatusTone.success : StatusTone.danger,
                ),
              ],
            ),
            if (available) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                Strings.bagsRemaining(store.bagsRemaining, store.dailyBagLimit),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
