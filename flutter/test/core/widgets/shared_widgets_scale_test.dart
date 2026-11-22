import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/core/widgets/app_card.dart';
import 'package:raghif/core/widgets/big_stat_display.dart';
import 'package:raghif/core/widgets/labeled_field.dart';
import 'package:raghif/core/widgets/number_stepper.dart';
import 'package:raghif/core/widgets/primary_button.dart';
import 'package:raghif/core/widgets/secondary_button.dart';
import 'package:raghif/core/widgets/status_chip.dart';

/// The shared widgets on the narrowest supported phone with the system font
/// at 200%: nothing may overflow (an overflow throws in a widget test).
void main() {
  testWidgets('shared widgets fit 360dp at TextScaler 2.0', (tester) async {
    tester.view.physicalSize = const Size(360, 800) * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2.0)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
        home: Scaffold(
          // Not a lazy ListView: every widget must be built and laid out.
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(text: 'اشترِ ربطة خبز اليوم', onPressed: () {}),
                const SizedBox(height: 8),
                const PrimaryButton(
                  text: 'تأكيد',
                  onPressed: null,
                  loading: true,
                ),
                const SizedBox(height: 8),
                SecondaryButton(text: 'تأجيل الحجز إلى الغد', onPressed: () {}),
                const SizedBox(height: 8),
                AppCard(
                  onTap: () {},
                  child: const Text('مخبز الأقصى — حي السلام، غزة'),
                ),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(text: 'مدفوع', tone: StatusTone.success),
                    StatusChip(text: 'قيد الانتظار', tone: StatusTone.warning),
                    StatusChip(text: 'ملغى', tone: StatusTone.danger),
                    StatusChip(text: 'الدفعة رقم 1', tone: StatusTone.neutral),
                  ],
                ),
                const SizedBox(height: 8),
                NumberStepper(
                  value: 300,
                  onChanged: (_) {},
                  decrementLabel: 'إنقاص',
                  incrementLabel: 'زيادة',
                ),
                const SizedBox(height: 8),
                const LabeledField(label: 'رقم الجوال', child: TextField()),
                const SizedBox(height: 8),
                const BigStatDisplay(label: 'الربطات المتبقية', value: '88'),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'الرئيسية'),
              NavigationDestination(
                icon: Icon(Icons.people),
                label: 'سجل الزبائن',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long),
                label: 'سجل المبيعات',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(PrimaryButton), findsNWidgets(2));
    expect(find.byTooltip('زيادة'), findsOneWidget);
    expect(find.byTooltip('إنقاص'), findsOneWidget);
    // The stepper value stays on one line at 2x.
    final value = tester.getSize(find.text('300'));
    expect(value.height, lessThan(value.width));
  });
}
