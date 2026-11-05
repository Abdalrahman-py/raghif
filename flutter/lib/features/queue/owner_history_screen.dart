import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/offline_notice.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/models/store_day_summary.dart';
import 'queue_controller.dart';

const _weekdayNames = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const _monthNames = [
  'كانون الثاني',
  'شباط',
  'آذار',
  'نيسان',
  'أيار',
  'حزيران',
  'تموز',
  'آب',
  'أيلول',
  'تشرين الأول',
  'تشرين الثاني',
  'كانون الأول',
];

/// Arabic weekday for an ISO `yyyy-MM-dd` date; empty if it doesn't parse.
String weekdayNameFor(String isoDate) {
  final d = DateTime.tryParse(isoDate);
  return d == null ? '' : _weekdayNames[d.weekday - 1];
}

/// `yyyy-MM` → "آب 2026"; falls back to the raw key.
String _monthLabel(String key) {
  final parts = key.split('-');
  final month = parts.length == 2 ? int.tryParse(parts[1]) : null;
  if (month == null || month < 1 || month > 12) return key;
  return '${_monthNames[month - 1]} ${parts[0]}';
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Owner history (walkthrough P0 #4): a day browser over the same queue the
/// owner already works with. Days come from one grouped query, so the table
/// shows "yesterday: 120 sold, 3 never picked up" without loading every row.
/// The list grows by a row a day, so it can be narrowed by month or by one
/// exact day.
class OwnerHistoryScreen extends StatefulWidget {
  const OwnerHistoryScreen({
    super.key,
    required this.controller,
    required this.storeId,
  });

  final QueueController controller;
  final dynamic storeId;

  @override
  State<OwnerHistoryScreen> createState() => _OwnerHistoryScreenState();
}

class _OwnerHistoryScreenState extends State<OwnerHistoryScreen> {
  // A year of days: the filters below work on this list, so it has to reach
  // further back than the old 30-day window or "last month" would be empty.
  late final Future<List<StoreDaySummary>> _days = widget.controller
      .dailySummariesForStore(widget.storeId, limit: 366);

  /// `yyyy-MM`, or null for all months.
  String? _month;

  /// `yyyy-MM-dd`, or null for no single-day filter.
  String? _day;

  void _openDay(String date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerHistoryDayScreen(
          controller: widget.controller,
          storeId: widget.storeId,
          date: date,
        ),
      ),
    );
  }

  Future<void> _pickDay(List<StoreDaySummary> days) async {
    final dates = days.map((d) => DateTime.tryParse(d.date)).nonNulls.toList()
      ..sort();
    if (dates.isEmpty) return;
    final current = _day == null ? null : DateTime.tryParse(_day!);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? dates.last,
      firstDate: dates.first,
      lastDate: dates.last,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _day = _isoDate(picked);
      _month = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 26
            ? 96
            : 64,
        title: Text(Strings.historyTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: FutureBuilder<List<StoreDaySummary>>(
              future: _days,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const OfflineNotice();
                }
                final days = snapshot.data ?? const <StoreDaySummary>[];
                if (days.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppCard(
                      child: Text(
                        Strings.historyEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }
                final months = <String>{
                  for (final d in days)
                    if (d.date.length >= 7) d.date.substring(0, 7),
                }.toList()..sort((a, b) => b.compareTo(a));
                final shown = days.where((d) {
                  if (_day != null) return d.date == _day;
                  if (_month != null) return d.date.startsWith(_month!);
                  return true;
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _Filters(
                      months: months,
                      month: _month,
                      day: _day,
                      onMonth: (m) => setState(() {
                        _month = m;
                        _day = null;
                      }),
                      onPickDay: () => _pickDay(days),
                      onClearDay: () => setState(() => _day = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (shown.isEmpty)
                      AppCard(
                        child: Text(
                          Strings.historyNoMatch,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    else
                      _HistoryTable(days: shown, onOpen: _openDay),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.months,
    required this.month,
    required this.day,
    required this.onMonth,
    required this.onPickDay,
    required this.onClearDay,
  });

  final List<String> months;
  final String? month;
  final String? day;
  final ValueChanged<String?> onMonth;
  final VoidCallback onPickDay;
  final VoidCallback onClearDay;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 160, maxWidth: 240),
          child: DropdownButtonFormField<String?>(
            key: ValueKey(month),
            initialValue: month,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: Strings.historyFilterMonth,
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(Strings.historyAllMonths),
              ),
              for (final m in months)
                DropdownMenuItem<String?>(
                  value: m,
                  child: Text(_monthLabel(m)),
                ),
            ],
            onChanged: onMonth,
          ),
        ),
        if (day == null)
          OutlinedButton.icon(
            onPressed: onPickDay,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: const Text(Strings.historyFilterDay),
          )
        else
          InputChip(
            avatar: const Icon(Icons.event, size: 18),
            label: Text('${weekdayNameFor(day!)} $day'),
            onDeleted: onClearDay,
            deleteButtonTooltipMessage: Strings.historyClearFilter,
          ),
      ],
    );
  }
}

/// Days as table rows: date (with weekday) | sold | collected | left over.
/// Counts are bare numbers under column headings, so a column reads straight
/// down; the whole row opens that day.
class _HistoryTable extends StatelessWidget {
  const _HistoryTable({required this.days, required this.onOpen});

  final List<StoreDaySummary> days;
  final ValueChanged<String> onOpen;

  static const _dateFlex = 4;
  static const _numFlex = 2;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final headStyle = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    );
    Widget head(String text) => Expanded(
      flex: _numFlex,
      child: Text(text, style: headStyle, textAlign: TextAlign.center),
    );
    Widget cell(Widget child) => Expanded(
      flex: _numFlex,
      child: Center(child: child),
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.neutralContainer,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: _dateFlex,
                  child: Text(Strings.historyColDate, style: headStyle),
                ),
                head(Strings.historyColSold),
                head(Strings.historyColCollected),
                head(Strings.historyColLeft),
              ],
            ),
          ),
          for (final day in days) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            InkWell(
              onTap: () => onOpen(day.date),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: _dateFlex,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weekdayNameFor(day.date),
                            style: textTheme.titleSmall,
                          ),
                          Text(day.date, style: textTheme.bodyMedium),
                          if (day.cashTotal > 0)
                            Text(
                              Strings.cashCollected(day.cashTotal),
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                        ],
                      ),
                    ),
                    cell(Text('${day.sold}')),
                    cell(
                      Text(
                        '${day.collected}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    cell(
                      Text(
                        '${day.notCollected}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: day.everythingCollected
                              ? AppColors.textSecondary
                              : AppColors.warning,
                          fontWeight: day.everythingCollected
                              ? FontWeight.w400
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One past day: the buyers and how each ended up, with the counts on top.
class OwnerHistoryDayScreen extends StatefulWidget {
  const OwnerHistoryDayScreen({
    super.key,
    required this.controller,
    required this.storeId,
    required this.date,
  });

  final QueueController controller;
  final dynamic storeId;
  final String date;

  @override
  State<OwnerHistoryDayScreen> createState() => _OwnerHistoryDayScreenState();
}

class _OwnerHistoryDayScreenState extends State<OwnerHistoryDayScreen> {
  late final Future<List<PurchaseModel>> _queue = widget.controller
      .queueForStore(widget.storeId, widget.date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 26
            ? 96
            : 64,
        title: Text(
          Strings.historyDayTitle(
            '${weekdayNameFor(widget.date)} ${widget.date}'.trim(),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: FutureBuilder<List<PurchaseModel>>(
              future: _queue,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return const OfflineNotice();
                final queue = snapshot.data ?? const <PurchaseModel>[];
                if (queue.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        Strings.historyEmpty,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }
                final collected = queue
                    .where((p) => p.status == PurchaseStatus.collected)
                    .length;
                final outstanding = queue.length - collected;

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: queue.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            StatusChip(
                              text: Strings.historySold(queue.length),
                              tone: StatusTone.neutral,
                            ),
                            StatusChip(
                              text: Strings.historyCollected(collected),
                              tone: StatusTone.success,
                            ),
                            if (outstanding > 0)
                              StatusChip(
                                text: Strings.historyNotCollected(outstanding),
                                tone: StatusTone.warning,
                              ),
                          ],
                        ),
                      );
                    }
                    return _BuyerHistoryRow(purchase: queue[index - 1]);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BuyerHistoryRow extends StatelessWidget {
  const _BuyerHistoryRow({required this.purchase});

  final PurchaseModel purchase;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (label, tone) = switch (purchase.status) {
      PurchaseStatus.collected => (
        Strings.statusCollectedShort,
        StatusTone.success,
      ),
      PurchaseStatus.notified => (
        Strings.statusNotifiedShort,
        StatusTone.warning,
      ),
      PurchaseStatus.waiting => (
        Strings.statusWaitingShort,
        StatusTone.neutral,
      ),
    };
    final meta = [
      if (purchase.userNationalId != null &&
          purchase.userNationalId!.isNotEmpty)
        purchase.userNationalId!,
      if (purchase.userPhone != null && purchase.userPhone!.isNotEmpty)
        purchase.userPhone!,
    ].join('  ·  ');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.accent,
                child: Icon(Icons.person_outline),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.userName ?? purchase.userPhone ?? '',
                      style: textTheme.titleMedium,
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(meta, style: textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusChip(text: label, tone: tone),
          ),
        ],
      ),
    );
  }
}
