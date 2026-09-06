import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../auth/session_store.dart';
import '../database/app_database.dart';
import '../network/api_client.dart';
import '../network/api_service.dart';
import '../notifications/notification_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/queue_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/queue_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/queue/queue_controller.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
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
  final authRepository = AuthRepositoryImpl(
    db: sl<AppDatabase>(),
    sessionStore: sl<SessionStore>(),
  );
  sl.registerSingleton<AuthRepository>(authRepository);

  final queueRepository = QueueRepositoryImpl(sl<AppDatabase>());
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
}
