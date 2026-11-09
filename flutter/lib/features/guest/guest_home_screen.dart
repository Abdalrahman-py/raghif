import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/i18n/strings.dart';
import '../../core/support/support_contact.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/models/store_model.dart';
import '../../domain/repositories/queue_repository.dart';
import '../auth/login_screen.dart';
import '../auth/registration_screen.dart';
import '../legal/legal_screens.dart';
import 'pending_booking.dart';

class _GuestData {
  const _GuestData({required this.all, required this.top});

  /// Every visible bakery (the summary counts these).
  final List<StoreModel> all;

  /// The busiest few, in rank order (the list shows these).
  final List<StoreModel> top;
}

/// What a visitor who is not signed in sees first: the bakeries and how many
/// bags each still has today, read-only. Nothing here needs an account, so the
/// value of the app is visible before any personal data is asked for. The
/// account is started only when the visitor chooses to book (or taps the
/// create-account button), one question at a time.
class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key, required this.repository});

  final QueueRepository repository;

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  late Future<_GuestData> _stores = _load();

  /// A visitor sees the five bakeries that sold most today, not the whole
  /// directory; the full list is for people with an account. Ranked from
  /// `stores` only: a signed-out visitor may read nothing else.
  static const topCount = 5;

  Future<_GuestData> _load() async {
    final stores = (await widget.repository.getStores())
        .where((s) => !s.isArchived)
        .toList();
    final top = [...stores]
      ..sort((a, b) {
        final sold = (b.dailyBagLimit - b.bagsRemaining).compareTo(
          a.dailyBagLimit - a.bagsRemaining,
        );
        return sold != 0 ? sold : a.name.compareTo(b.name);
      });
    return _GuestData(all: stores, top: top.take(topCount).toList());
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _stores = next);
    await next.catchError((_) => const _GuestData(all: [], top: []));
  }

  void _signUp([StoreModel? store]) {
    // Remembered so the booking can continue once there is an account.
    PendingBooking.set(store?.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegistrationScreen(storeName: store?.name),
      ),
    );
  }

  void _login() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _showStore(StoreModel store) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _StoreSheet(
        store: store,
        onBook: () {
          Navigator.of(sheetContext).pop();
          _signUp(store);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_GuestData>(
            future: _stores,
            builder: (context, snapshot) {
              final stores = snapshot.data?.all;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/stitch_loaf.svg',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'رغيف',
                          style: textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    Strings.guestTagline,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _summary(stores, textTheme, muted),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    Strings.guestStoresTitle,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._storeList(snapshot, textTheme, muted),
                  const SizedBox(height: AppSpacing.lg),
                  _howItWorks(textTheme, muted),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    text: Strings.guestCreateAccount,
                    onPressed: _signUp,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: TextButton(
                      onPressed: _login,
                      child: const Text(Strings.guestHaveAccount),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    Strings.ownerViaSupport,
                    key: const Key('guest-owner-note'),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const SupportWhatsAppButton(
                    key: Key('guest-owner-whatsapp'),
                    message: Strings.ownerRequestMessage,
                    label: 'تواصل معنا لإضافة مخبزك',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LegalScreen.privacy(),
                          ),
                        ),
                        child: const Text(Strings.privacyTitle),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LegalScreen.terms(),
                          ),
                        ),
                        child: const Text(Strings.termsTitle),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summary(List<StoreModel>? stores, TextTheme textTheme, Color muted) {
    if (stores == null) return const SizedBox.shrink();
    final open = stores.where((s) => s.canPurchase).toList();
    final bags = open.fold<int>(0, (sum, s) => sum + s.bagsRemaining);
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.bakery_dining_rounded, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              open.isEmpty
                  ? Strings.guestSummaryNone
                  : Strings.guestSummary(open.length, bags),
              key: const Key('guest-summary'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _storeList(
    AsyncSnapshot<_GuestData> snapshot,
    TextTheme textTheme,
    Color muted,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (snapshot.hasError) {
      return [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                Strings.guestLoadError,
                key: const Key('guest-error'),
                style: textTheme.bodyLarge?.copyWith(color: AppColors.danger),
              ),
              TextButton(
                onPressed: _refresh,
                child: const Text(Strings.guestRetry),
              ),
            ],
          ),
        ),
      ];
    }
    final stores = snapshot.data!.top;
    if (stores.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            Strings.guestNoStores,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: muted),
          ),
        ),
      ];
    }
    return [
      for (final store in stores) ...[
        _StoreCard(store: store, onTap: () => _showStore(store)),
        const SizedBox(height: AppSpacing.sm),
      ],
    ];
  }

  Widget _howItWorks(TextTheme textTheme, Color muted) {
    const steps = [Strings.guestHow1, Strings.guestHow2, Strings.guestHow3];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Strings.guestHowTitle,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.accentContainer,
                    child: Text('${i + 1}', style: textTheme.labelLarge),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(steps[i], style: textTheme.bodyLarge)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The one line that says whether a bakery can be booked right now.
({String text, StatusTone tone}) _availability(StoreModel store) {
  if (store.isPaused) {
    return (text: Strings.storePausedBadge, tone: StatusTone.neutral);
  }
  if (!store.isOpen) {
    return (text: Strings.storeClosedBadge, tone: StatusTone.neutral);
  }
  if (store.isSoldOut) {
    return (text: Strings.soldOut, tone: StatusTone.danger);
  }
  return (text: Strings.available, tone: StatusTone.success);
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.onTap});

  final StoreModel store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final status = _availability(store);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (store.area.isNotEmpty)
                  Text(
                    store.area,
                    style: textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  Strings.bagsRemaining(
                    store.bagsRemaining,
                    store.dailyBagLimit,
                  ),
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          StatusChip(text: status.text, tone: status.tone),
        ],
      ),
    );
  }
}

class _StoreSheet extends StatelessWidget {
  const _StoreSheet({required this.store, required this.onBook});

  final StoreModel store;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final status = _availability(store);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              store.name,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (store.area.isNotEmpty)
              Text(
                store.area,
                style: textTheme.bodyLarge?.copyWith(color: muted),
              ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusChip(text: status.text, tone: status.tone),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              Strings.bagsRemaining(store.bagsRemaining, store.dailyBagLimit),
              style: textTheme.titleMedium,
            ),
            if (store.hasPurchaseWindow) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                Strings.purchaseWindowRange(store.openTime!, store.closeTime!),
                style: textTheme.bodyLarge?.copyWith(color: muted),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(text: Strings.guestBook, onPressed: onBook),
          ],
        ),
      ),
    );
  }
}
