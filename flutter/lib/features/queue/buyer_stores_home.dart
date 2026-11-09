import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/offline_notice.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../domain/models/store_list_entry.dart';
import '../../domain/models/store_model.dart';
import '../auth/demo_accounts.dart';
import '../locations/location_logic.dart';
import 'purchase_flow.dart';
import 'queue_controller.dart';
import 'store_details_screen.dart';

/// The buyer's home: one list with filters. The first (and default) filter is
/// the bakeries the buyer bought from lately, then "all", then one chip per
/// governorate; open bakeries come first. Each card buys a bag in one tap
/// (straight to payment) or opens the bakery.
class BuyerStoresHome extends StatefulWidget {
  const BuyerStoresHome({
    super.key,
    required this.controller,
    required this.currentUser,
  });

  final QueueController controller;
  final DemoUser currentUser;

  @override
  State<BuyerStoresHome> createState() => _BuyerStoresHomeState();
}

class _BuyerStoresHomeState extends State<BuyerStoresHome> {
  /// null = all governorates.
  String? _governorate;

  /// The "my bakeries" filter, on by default; ignored while the buyer has no
  /// bakery of their own yet (then the list is simply everything).
  bool _mine = true;

  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.watchStoreListFor(widget.currentUser.id);
  }

  void _buy(StoreListEntry entry) => startPurchase(
    context,
    controller: widget.controller,
    currentUser: widget.currentUser,
    storeId: entry.store.id,
  );

  void _open(StoreListEntry entry) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StoreDetailsScreen(
        controller: widget.controller,
        currentUser: widget.currentUser,
        entry: entry,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                if (widget.controller.storeListFailed) {
                  return SingleChildScrollView(
                    child: OfflineNotice(
                      onRetry: () => widget.controller.watchStoreListFor(
                        widget.currentUser.id,
                      ),
                    ),
                  );
                }
                if (!widget.controller.storeListLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = widget.controller.storeList
                    .where((e) => !e.store.isArchived)
                    .toList();
                final mine = recentBakeries(all);
                final present = [
                  for (final g in governorates)
                    if (all.any((e) => governorateOf(e.store) == g)) g,
                ];
                final showMine = _mine && mine.isNotEmpty;
                final selected = showMine || !present.contains(_governorate)
                    ? null
                    : _governorate;
                final q = _query.trim();
                final shown = sortByOpenness(
                  (showMine ? mine : all)
                      .where(
                        (e) =>
                            (selected == null ||
                                governorateOf(e.store) == selected) &&
                            (q.isEmpty ||
                                e.store.name.contains(q) ||
                                e.store.area.contains(q)),
                      )
                      .toList(),
                );

                return RefreshIndicator(
                  onRefresh: widget.controller.refreshAll,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    children: [
                      if (widget.controller.storeListStale) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.warningContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cloud_off_outlined,
                                color: AppColors.onWarningContainer,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Expanded(
                                child: Text(
                                  'لا يوجد اتصال. نعرض آخر قائمة محفوظة وقد تكون قديمة.',
                                  style: TextStyle(
                                    color: AppColors.onWarningContainer,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => widget.controller
                                    .watchStoreListFor(widget.currentUser.id),
                                child: const Text('تحديث'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        showMine ? 'مخابزي' : 'كل المخابز',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        key: const Key('store-search'),
                        controller: _search,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: Strings.storeSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'مسح البحث',
                                  onPressed: () => setState(() {
                                    _search.clear();
                                    _query = '';
                                  }),
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (present.isNotEmpty || mine.isNotEmpty)
                        SizedBox(
                          height: 48,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              if (mine.isNotEmpty)
                                _GovChip(
                                  key: const Key('filter-mine'),
                                  label: 'مخابزي',
                                  selected: showMine,
                                  onSelected: () => setState(() {
                                    _mine = true;
                                    _governorate = null;
                                  }),
                                ),
                              _GovChip(
                                label: 'الكل',
                                selected: !showMine && selected == null,
                                onSelected: () => setState(() {
                                  _mine = false;
                                  _governorate = null;
                                }),
                              ),
                              for (final g in present)
                                _GovChip(
                                  label: g,
                                  selected: selected == g,
                                  onSelected: () => setState(() {
                                    _mine = false;
                                    _governorate = g;
                                  }),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      if (shown.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            q.isNotEmpty
                                ? Strings.noMatchingStores
                                : Strings.noStores,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge,
                          ),
                        ),
                      for (final entry in shown) ...[
                        BakeryCard(
                          entry: entry,
                          onBuy: () => _buy(entry),
                          onOpen: () => _open(entry),
                        ),
                        const SizedBox(height: AppSpacing.sm),
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

/// Up to five bakeries the buyer has bought from (or has an order at today),
/// most recent first.
List<StoreListEntry> recentBakeries(List<StoreListEntry> entries) {
  final familiar = entries.where((e) => e.isFamiliar).toList()
    ..sort((a, b) {
      final byDate = (b.lastPurchaseDate ?? '').compareTo(
        a.lastPurchaseDate ?? '',
      );
      return byDate != 0 ? byDate : a.store.name.compareTo(b.store.name);
    });
  return familiar.take(5).toList();
}

/// Bakeries that can sell right now first, then the ones that are open but out
/// of bags or paused, then the closed ones; by name inside each group.
List<StoreListEntry> sortByOpenness(List<StoreListEntry> entries) {
  int rank(StoreModel s) => s.isAvailable ? 0 : (s.isOpen ? 1 : 2);
  return [...entries]..sort((a, b) {
    final byRank = rank(a.store).compareTo(rank(b.store));
    return byRank != 0 ? byRank : a.store.name.compareTo(b.store.name);
  });
}

class _GovChip extends StatelessWidget {
  const _GovChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
    child: FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    ),
  );
}

/// One bakery: name and place on top, then bags left and hours side by side,
/// then the two actions. Green = open with bags left; red = closed, paused or
/// sold out.
class BakeryCard extends StatelessWidget {
  const BakeryCard({
    super.key,
    required this.entry,
    required this.onBuy,
    required this.onOpen,
  });

  final StoreListEntry entry;
  final VoidCallback onBuy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final store = entry.store;
    final textTheme = Theme.of(context).textTheme;
    final ok = store.isAvailable;
    final tone = ok ? AppColors.success : AppColors.danger;
    final toneBg = ok ? AppColors.successContainer : AppColors.dangerContainer;
    final label = ok
        ? 'مفتوح'
        : store.isPaused
        ? Strings.storePausedBadge
        : store.isOpen
        ? Strings.soldOut
        : Strings.storeClosedBadge;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: toneBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.storefront_outlined, color: tone),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name, style: textTheme.titleMedium),
                    if (store.area.isNotEmpty)
                      Text(store.area, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: toneBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _Fact(
                  icon: Icons.bakery_dining_outlined,
                  text: ok
                      ? '${store.bagsRemaining} من ${store.dailyBagLimit} ربطة'
                      : 'لا توجد ربطات الآن',
                  color: tone,
                ),
              ),
              Expanded(
                child: _Fact(
                  icon: Icons.schedule_outlined,
                  text: store.hasPurchaseWindow
                      ? '${store.openTime} – ${store.closeTime}'
                      : 'الموعد غير محدد',
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: PrimaryButton(
                  text: 'اشترِ ربطة',
                  onPressed: ok ? onBuy : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: SecondaryButton(text: 'عرض المخبز', onPressed: onOpen),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
      ),
    ],
  );
}
