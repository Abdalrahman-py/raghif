import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../firebase_options.dart';
import '../auth/session_store.dart';
import '../config/env.dart';
import '../database/app_database.dart';
import '../notifications/fcm_service.dart';
import '../notifications/notification_service.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_queue_repository.dart';
import '../../data/sync/queue_sync_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/queue_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/queue/queue_controller.dart';

final GetIt sl = GetIt.instance;

/// Supabase is required, not optional.
///
/// The old `USE_SUPABASE` flag picked between a Supabase path and a
/// drift-only one that seeded and decided everything on-device. Keeping
/// both meant two disagreeing sources of truth, which is what shipped the
/// batch-number mismatch. There is one path now; drift is a cache behind
/// it.
Future<void> initDependencies() async {
  await Env.load();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );
  sl.registerSingleton<SupabaseClient>(Supabase.instance.client);

  final db = AppDatabase();
  sl.registerSingleton<AppDatabase>(db);

  final sessionStore = SessionStore();
  sl.registerSingleton<SessionStore>(sessionStore);

  sl.registerSingleton<NotificationService>(NotificationService.instance);
  await sl<NotificationService>().init();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final fcmService = FcmService(sl<SupabaseClient>());
  sl.registerSingleton<FcmService>(fcmService);
  await fcmService.init();

  sl.registerSingleton<AuthRepository>(
    SupabaseAuthRepository(
      client: sl<SupabaseClient>(),
      db: sl<AppDatabase>(),
      sessionStore: sl<SessionStore>(),
      fcmService: sl<FcmService>(),
    ),
  );

  final sync = QueueSyncService(client: sl<SupabaseClient>(), db: db);
  sl.registerSingleton<QueueSyncService>(sync);
  sl.registerSingleton<QueueRepository>(
    SupabaseQueueRepository(
      client: sl<SupabaseClient>(),
      db: db,
      sync: sync,
    ),
  );

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      authRepository: sl<AuthRepository>(),
      sessionStore: sl<SessionStore>(),
    ),
  );
  sl.registerLazySingleton<QueueController>(
    () => QueueController(sl<QueueRepository>()),
  );

  // Stores are world-readable, so the bakery list is warm before login.
  // Nothing is seeded here: the demo world lives in Postgres now
  // (seed_demo_* / the seed-demo Edge Function action).
  await sync.pullStores();
}
