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
import 'owner_customers_screen.dart';
import 'owner_queue_screen.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';

/// UI_SPEC.md OwnerDashboardScreen: "Remaining: X / Y" is the single largest
/// element on screen. Purchase window is set by open/close times, not a
/// manual switch. Batch size lives on [OwnerQueueScreen] — it groups the
/// queue, so it's edited next to the queue rather than here.
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({
    super.key,
    required this.controller,
    required this.storeId,
  });

  static const routeName = 'ownerDashboard';

  final QueueController controller;
  final dynamic storeId;

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _allocation = 300;
  String? _openTime;
  String? _closeTime;
  bool _stepperInitialized = false;

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
          if (!_stepperInitialized &&
              widget.controller.storesLoaded &&
              store != null) {
            _allocation = store.dailyBagLimit;
            _openTime = store.openTime;
            _closeTime = store.closeTime;
            _stepperInitialized = true;
          }
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Center(
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
                                  Text(
                                    Strings.purchaseWindowTimesLabel,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _TimePickerField(
                                          label: Strings.openTimeLabel,
                                          time: _openTime,
                                          onTap: () =>
                                              _pickTime(isOpenTime: true),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: _TimePickerField(
                                          label: Strings.closeTimeLabel,
                                          time: _closeTime,
                                          onTap: () =>
                                              _pickTime(isOpenTime: false),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppCard(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      Strings.allocationLabel,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
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
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SecondaryButton(
                              text: Strings.saveAllocation,
                              onPressed: () => widget.controller.saveAllocation(
                                widget.storeId,
                                dailyBagLimit: _allocation,
                                batchSize: store?.batchSize ?? 20,
                                today: todayDateString(),
                                openTime: _openTime,
                                closeTime: _closeTime,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                          const SizedBox(height: AppSpacing.sm),
                          SecondaryButton(
                            text: Strings.customersButton,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OwnerCustomersScreen(
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
              ],
            ),
          );
        },
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(time ?? Strings.notSetLabel, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}
