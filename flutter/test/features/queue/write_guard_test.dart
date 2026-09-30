import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/domain/repositories/queue_repository.dart';
import 'package:raghif/features/queue/write_guard.dart';

void main() {
  Future<bool?> run(
    WidgetTester tester,
    Future<void> Function() write,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await guardWrite(context, write),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    return result;
  }

  testWidgets('a successful write returns true and shows nothing',
      (tester) async {
    final result = await run(tester, () async {});

    expect(result, isTrue);
    expect(find.text(Strings.offlineWriteFailed), findsNothing);
  });

  testWidgets('a failed write returns false and says it did not happen',
      (tester) async {
    final result = await run(
      tester,
      () async => throw const BackendUnavailableException('offline'),
    );

    expect(result, isFalse);
    expect(find.text(Strings.offlineWriteFailed), findsOneWidget);
  });
}
