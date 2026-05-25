import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../storage/token_storage.dart';
import '../storage/token_storage_impl.dart';
import '../storage/session_snapshot_storage.dart';
import '../storage/session_snapshot_storage_impl.dart';
import '../network/dio/dio_factory.dart';
import '../network/dio/dio_client.dart';
import 'package:dio/dio.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_use_case.dart';
import '../../features/auth/domain/usecases/logout_use_case.dart';
import '../../features/auth/domain/usecases/restore_session_use_case.dart';
import '../../features/auth/domain/usecases/register_use_case.dart';
import '../../features/auth/domain/usecases/confirm_registration_use_case.dart';
import '../../features/auth/domain/usecases/forgot_password_use_case.dart';
import '../../features/auth/domain/usecases/confirm_forgot_password_use_case.dart';
import '../../features/subscription/data/datasources/subscription_remote_data_source.dart';
import '../../features/subscription/data/repositories/subscription_repository_impl.dart';
import '../../features/subscription/domain/repositories/subscription_repository.dart';
import '../../features/subscription/domain/usecases/load_subscription_plans_use_case.dart';

final GetIt locator = GetIt.instance;

Future<void> setupDependencies({bool enableLogging = false}) async {
  // Secure storage
  locator.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // Token storage
  locator.registerLazySingleton<TokenStorage>(
    () => TokenStorageImpl(locator<FlutterSecureStorage>()),
  );

  // Session snapshot storage
  final prefs = await SharedPreferences.getInstance();
  locator.registerLazySingleton<SharedPreferences>(() => prefs);
  locator.registerLazySingleton<SessionSnapshotStorage>(
    () => SessionSnapshotStorageImpl(locator<SharedPreferences>()),
  );

  // Logger
  locator.registerLazySingleton<Logger>(() => Logger());

  // Dio
  final dio = DioFactory.createDio(
    tokenStorage: locator<TokenStorage>(),
    logger: locator<Logger>(),
    enableLogging: enableLogging,
  );

  locator.registerLazySingleton<Dio>(() => dio);
  locator.registerLazySingleton<DioClient>(() => DioClient(locator<Dio>()));

  // Auth
  locator.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      locator<AuthRemoteDataSource>(),
      locator<TokenStorage>(),
      locator<SessionSnapshotStorage>(),
    ),
  );
  locator.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<RestoreSessionUseCase>(
    () => RestoreSessionUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<ConfirmRegistrationUseCase>(
    () => ConfirmRegistrationUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<ForgotPasswordUseCase>(
    () => ForgotPasswordUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<ConfirmForgotPasswordUseCase>(
    () => ConfirmForgotPasswordUseCase(locator<AuthRepository>()),
  );

  // Subscription
  locator.registerLazySingleton<SubscriptionRemoteDataSource>(
    () => SubscriptionRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(locator<SubscriptionRemoteDataSource>()),
  );
  locator.registerLazySingleton<LoadSubscriptionPlansUseCase>(
    () => LoadSubscriptionPlansUseCase(locator<SubscriptionRepository>()),
  );
}
