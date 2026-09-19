import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../firebase_options.dart';
import '../auth/session_store.dart';
import '../config/env.dart';
import '../database/app_database.dart';
import '../network/api_client.dart';
import '../network/api_service.dart';
import '../notifications/fcm_service.dart';
import '../notifications/notification_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/demo_content_seeder.dart';
import '../../data/repositories/queue_repository_impl.dart';
import '../../data/repositories/synced_queue_repository.dart';
import '../../data/sync/queue_sync_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/queue_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/queue/queue_controller.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  await Env.load();

  // Supabase backend (behind a flag until Phase 2/3 are validated end to
  // end — see docs/supabase-migration-plan.md). Local drift stays the
  // offline cache/read layer either way.
  if (Env.useSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
    sl.registerSingleton<SupabaseClient>(Supabase.instance.client);

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final fcmService = FcmService(sl<SupabaseClient>());
    sl.registerSingleton<FcmService>(fcmService);
    await fcmService.init();
  }

  // Database & Local Storage
  final db = AppDatabase();
  sl.registerSingleton<AppDatabase>(db);

  final sessionStore = SessionStore();
  sl.registerSingleton<SessionStore>(sessionStore);

  sl.registerSingleton<NotificationService>(NotificationService.instance);
  await sl<NotificationService>().init();

  // Network Layer
  final dio = ApiClient.createDio();
  sl.registerSingleton<Dio>(dio);
  sl.registerSingleton<ApiService>(ApiService(dio));

  // Repositories
  final AuthRepository authRepository = Env.useSupabase
      ? SupabaseAuthRepository(
          client: sl<SupabaseClient>(),
          db: sl<AppDatabase>(),
          sessionStore: sl<SessionStore>(),
          fcmService: sl<FcmService>(),
        )
      : AuthRepositoryImpl(
          db: sl<AppDatabase>(),
          sessionStore: sl<SessionStore>(),
        );
  sl.registerSingleton<AuthRepository>(authRepository);

  final localQueueRepository = QueueRepositoryImpl(sl<AppDatabase>());
  final QueueRepository queueRepository = Env.useSupabase
      ? SyncedQueueRepository(
          local: localQueueRepository,
          client: sl<SupabaseClient>(),
          db: sl<AppDatabase>(),
          sync: QueueSyncService(
            client: sl<SupabaseClient>(),
            db: sl<AppDatabase>(),
          ),
        )
      : localQueueRepository;
  sl.registerSingleton<QueueRepository>(queueRepository);

  // Blocs & Controllers
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      authRepository: sl<AuthRepository>(),
      sessionStore: sl<SessionStore>(),
    ),
  );
  sl.registerLazySingleton<QueueController>(
    () => QueueController(sl<QueueRepository>()),
  );

  // Seed default data
  await authRepository.ensureSeeded();
  await queueRepository.ensureSeeded();
  // Richer demo content for the walkthrough (fresh installs only; no-op when
  // the DB already carries purchases or more than the base footprint).
  await DemoContentSeeder(db).seedIfFresh();
}
