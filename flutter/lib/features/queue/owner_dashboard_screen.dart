import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/big_stat_display.dart';
import '../../core/widgets/number_stepper.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../auth/bloc/auth_bloc.dart';
import 'owner_queue_screen.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';

/// UI_SPEC.md OwnerDashboardScreen: "Remaining: X / Y" is the single largest
/// element on screen; purchase-window is a large labeled switch, not an
/// icon-only toggle; batch size uses a stepper over free-text entry.
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
  late int _allocation;
  late int _batchSize;

  @override
  void initState() {
    super.initState();
    final store = widget.controller.storeById(widget.storeId);
    _allocation = store?.dailyBagLimit ?? 0;
    _batchSize = store?.batchSize ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.ownerDashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: Strings.logout,
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequestedEvent()),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final store = widget.controller.storeById(widget.storeId);
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        store?.name ?? '',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BigStatDisplay(
                              label: Strings.remainingLabel,
                              value:
                                  '${store?.bagsRemaining ?? 0} / ${store?.dailyBagLimit ?? 0}',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  Strings.purchaseWindowOpen,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Switch(
                                  value: store?.isOpen ?? false,
                                  onChanged: (value) => widget.controller
                                      .setPurchaseWindowOpen(
                                        widget.storeId,
                                        value,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    Strings.allocationLabel,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                NumberStepper(
                                  value: _allocation,
                                  onChanged: (v) =>
                                      setState(() => _allocation = v),
                                  decrementLabel: Strings.decreaseValue,
                                  incrementLabel: Strings.increaseValue,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    Strings.batchSizeLabel,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                NumberStepper(
                                  value: _batchSize,
                                  onChanged: (v) =>
                                      setState(() => _batchSize = v),
                                  decrementLabel: Strings.decreaseValue,
                                  incrementLabel: Strings.increaseValue,
                                  min: 1,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SecondaryButton(
                        text: Strings.saveAllocation,
                        onPressed: () => widget.controller.saveAllocation(
                          widget.storeId,
                          dailyBagLimit: _allocation,
                          batchSize: _batchSize,
                          today: todayDateString(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        text: Strings.goToQueue,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OwnerQueueScreen(
                              controller: widget.controller,
                              storeId: widget.storeId,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
