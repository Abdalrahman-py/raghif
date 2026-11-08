import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../firebase_options.dart';
import '../cache/offline_cache.dart';
import '../config/env.dart';
import '../connectivity/connectivity_monitor.dart';
import '../notifications/fcm_service.dart';
import '../notifications/notification_service.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_queue_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/queue_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/supabase_notification_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/queue/queue_controller.dart';

final GetIt sl = GetIt.instance;

/// Starts push (permission prompt, token registration, listeners) without
/// holding up the app: called once after the first frame, never awaited by
/// start-up, and failures are swallowed (no push must never mean no app).
void startPushLater() {
  if (kIsWeb || !sl.isRegistered<FcmService>()) return;
  Future<void>.delayed(const Duration(milliseconds: 1500), () async {
    try {
      await sl<FcmService>().init();
    } catch (_) {}
  });
}

/// Supabase is required, not optional.
///
/// The old `USE_SUPABASE` flag picked between a Supabase path and a
/// drift-only one that seeded and decided everything on-device. Keeping
/// both meant two disagreeing sources of truth, which is what shipped the
/// batch-number mismatch. There is one path now, and no on-device database:
/// every screen reads Supabase.
Future<void> initDependencies() async {
  await Env.load();

  // Independent of one another, so they run together instead of one after the
  // other: Supabase restoring its stored session, the local-notification
  // channel, and Firebase (not on web). Start-up waits for the slowest only.
  await Future.wait<void>([
    Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    ),
    NotificationService.instance.init(),
    if (!kIsWeb)
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);
  sl.registerSingleton<SupabaseClient>(Supabase.instance.client);
  sl.registerSingleton<NotificationService>(NotificationService.instance);

  // Registered only: init() asks for the notification permission, which waits
  // for the user. It is started after the first frame (see startPushLater).
  final fcmService = FcmService(sl<SupabaseClient>());
  sl.registerSingleton<FcmService>(fcmService);

  sl.registerSingleton<AuthRepository>(
    SupabaseAuthRepository(
      client: sl<SupabaseClient>(),
      fcmService: sl<FcmService>(),
    ),
  );

  sl.registerSingleton<QueueRepository>(
    SupabaseQueueRepository(client: sl<SupabaseClient>()),
  );

  fcmService.onForegroundPush = () => sl<QueueRepository>().refresh();

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
  sl.registerSingleton<NotificationRepository>(
    SupabaseNotificationRepository(client: sl<SupabaseClient>()),
  );
  sl.registerSingleton<ConnectivityMonitor>(ConnectivityMonitor()..start());
  sl.registerLazySingleton<QueueController>(
    () => QueueController(sl<QueueRepository>(), OfflineCache()),
  );
}
