import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/domain/models/purchase_model.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/queue/owner_customers_screen.dart';
import 'package:raghif/features/queue/owner_history_screen.dart';
import 'package:raghif/features/queue/owner_queue_screen.dart';
import 'package:raghif/features/queue/qr_scanner_screen.dart';
import 'package:raghif/features/queue/queue_logic.dart';
import 'package:raghif/features/verification/wallet_verification_screen.dart';

import '../goldens/test_fonts.dart';
import '../support/fake_auth_repository.dart';
import '../support/queue_test_harness.dart';

/// Exercise the production scanner's error handling without a camera or
/// permission dialog. This fixture represents camera unavailable, not a camera
/// preview or proof of device QR decoding.
class _UnavailableScannerPlatform extends MobileScannerPlatform {
  int starts = 0;

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    starts++;
    throw const MobileScannerException(
      errorCode: MobileScannerErrorCode.permissionDenied,
    );
  }

  @override
  Widget buildCameraView() => const SizedBox.shrink();

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String name,
) async {
  final output = Platform.environment['STITCH_SCREENSHOT_DIR'];
  if (output == null || output.isEmpty) return;
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('PNG encoding failed for $name');
      final directory = await Directory(output).create(recursive: true);
      await File(
        '${directory.path}${Platform.pathSeparator}$name.png',
      ).writeAsBytes(bytes.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  final viewports = [
    (name: 'phone', size: const Size(390, 884), scale: 1.0),
    (name: 'small_large_text', size: const Size(320, 640), scale: 1.5),
    (name: 'landscape', size: const Size(884, 390), scale: 1.0),
  ];

  for (final viewport in viewports) {
    testWidgets('Stitch remaining production screens: ${viewport.name}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport.size;
      addTearDown(tester.view.reset);
      await loadAppFonts(tester);

      final auth = AuthBloc(authRepository: FakeAuthRepository());
      addTearDown(auth.close);
      final harness = buildQueueHarness();
      final boundaryKey = GlobalKey();

      // The scanner owns an AudioPlayer even when no QR is decoded. Stub its
      // initialization/disposal channels so this test never starts native audio.
      final messenger = tester.binding.defaultBinaryMessenger;
      const audioChannel = MethodChannel('xyz.luan/audioplayers');
      const globalAudioChannel = MethodChannel('xyz.luan/audioplayers.global');
      const globalAudioEvents = MethodChannel(
        'xyz.luan/audioplayers.global/events',
      );
      final playerEventChannels = <MethodChannel>[];
      messenger.setMockMethodCallHandler(audioChannel, (call) async {
        if (call.method == 'create') {
          final arguments = call.arguments as Map;
          final channel = MethodChannel(
            'xyz.luan/audioplayers/events/${arguments['playerId']}',
          );
          playerEventChannels.add(channel);
          messenger.setMockMethodCallHandler(channel, (_) async => null);
        }
        return null;
      });
      messenger.setMockMethodCallHandler(globalAudioChannel, (_) async => null);
      messenger.setMockMethodCallHandler(globalAudioEvents, (_) async => null);
      addTearDown(() {
        for (final channel in [
          audioChannel,
          globalAudioChannel,
          globalAudioEvents,
          ...playerEventChannels,
        ]) {
          messenger.setMockMethodCallHandler(channel, null);
        }
      });

      final originalScanner = MobileScannerPlatform.instance;
      final scanner = _UnavailableScannerPlatform();
      MobileScannerPlatform.instance = scanner;
      addTearDown(() => MobileScannerPlatform.instance = originalScanner);

      // Bounded pumps also work for the waiting screen's indeterminate spinner.
      // Never pumpAndSettle while a waiting indicator may still be mounted.
      Future<void> paint() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
      }

      void check(String name) {
        expect(
          tester.takeException(),
          isNull,
          reason: '$name at ${viewport.name}',
        );
      }

      Future<void> show(Widget screen) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await paint();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: BlocProvider<AuthBloc>.value(
              value: auth,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(viewport.scale)),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: child!,
                  ),
                ),
                home: screen,
              ),
            ),
          ),
        );
        await paint();
        check('${screen.runtimeType} initial layout');
      }

      Future<void> capture(String name) async {
        check(name);
        if (viewport.name == 'phone') {
          await _capture(tester, boundaryKey, name);
        }
      }

      Future<void> reach(Finder target, String name) async {
        final scrolls = find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
        );
        if (target.hitTestable().evaluate().isEmpty &&
            scrolls.evaluate().isNotEmpty) {
          await tester.scrollUntilVisible(
            target,
            180,
            scrollable: scrolls.first,
            maxScrolls: 50,
          );
        }
        await tester.ensureVisible(target);
        await paint();
        expect(target.hitTestable(), findsOneWidget, reason: name);
        check('$name after scrolling');
      }

      try {
        await show(
          WalletVerificationScreen(
            number: '0599123456',
            onVerify: (_) {},
            onLogout: () {},
          ),
        );
        expect(find.text(Strings.walletVerifyTitle), findsOneWidget);
        await capture('wallet_verification_number');
        await tester.ensureVisible(find.text(Strings.walletVerifySend));
        await tester.tap(find.text(Strings.walletVerifySend));
        await paint();
        expect(find.text(Strings.walletVerifyConfirm), findsOneWidget);
        await capture('wallet_verification_code');
        await reach(find.text(Strings.walletVerifyConfirm), 'verify confirm');

        // Seed all queue statuses and another day through the fake repository.
        // No purchase or owner action in this fixture reaches a remote backend.
        final date = todayDateString();
        const historicalDate = '2025-01-15';
        final names = ['أحمد ناصر', 'محمود سعيد', 'ليلى منصور', 'سارة خليل'];
        for (var i = 0; i < names.length; i++) {
          final userId = i == 0 ? seededBuyerId : 'visual-buyer-$i';
          harness.repo.addUser(userId, name: names[i], phone: '059911111$i');
          harness.repo.givenPurchase(
            userId: userId,
            storeId: seededStoreId,
            date: date,
            batchNumber: i < 2 ? 1 : 2,
            status: i == 0
                ? PurchaseStatus.notified
                : i == 1
                ? PurchaseStatus.collected
                : PurchaseStatus.waiting,
          );
          harness.repo.givenPurchase(
            userId: userId,
            storeId: seededStoreId,
            date: historicalDate,
            status: i.isEven
                ? PurchaseStatus.collected
                : PurchaseStatus.waiting,
          );
        }
        harness.repo.currentUserId = seededOwnerId;

        await show(
          OwnerQueueScreen(
            controller: harness.controller,
            storeId: seededStoreId,
          ),
        );
        await capture('owner_queue');
        await reach(find.text(Strings.markReceived), 'mark received');
        await reach(find.text(Strings.notifyNextBatch(2)), 'notify next batch');
        await tester.tap(find.text(Strings.notifyNextBatch(2)));
        await paint();
        expect(find.text(Strings.notifyConfirmTitle), findsOneWidget);
        check('notify confirmation dialog');
        await reach(find.text(Strings.cancelLabel), 'cancel notification');
        await tester.tap(find.text(Strings.cancelLabel));
        await paint();

        await show(
          OwnerCustomersScreen(
            controller: harness.controller,
            storeId: seededStoreId,
          ),
        );
        await capture('owner_customers');
        await reach(find.text(names.last), 'last customer');
        expect(find.text(Strings.totalPurchasesCount(2)), findsWidgets);

        await show(
          OwnerHistoryScreen(
            controller: harness.controller,
            storeId: seededStoreId,
          ),
        );
        await capture('owner_history');
        await reach(find.text(historicalDate), 'historical day');
        await tester.tap(find.text(historicalDate));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await paint();
        expect(find.byType(OwnerHistoryDayScreen), findsOneWidget);
        expect(find.text(Strings.historySold(4)), findsOneWidget);
        expect(find.text(Strings.historyCollected(2)), findsOneWidget);
        await capture('owner_history_day');
        await reach(find.text(names.last), 'last historical buyer');

        await show(
          QrScannerScreen(
            controller: harness.controller,
            storeId: seededStoreId,
          ),
        );
        await paint();
        expect(scanner.starts, greaterThan(0));
        expect(find.text(Strings.scanCameraError), findsOneWidget);
        await capture('qr_scanner_camera_unavailable');
        await reach(find.text(Strings.scanAgain), 'retry scanner');
        await reach(find.text(Strings.back), 'scanner back');
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await paint();
        harness.controller.dispose();
        harness.repo.dispose();
        await tester.pump();
      }
    });
  }
}
