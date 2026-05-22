import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/session_snapshot_storage.dart';
import '../../domain/entities/login_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/confirm_forgot_password_request_model.dart';
import '../models/confirm_registration_request_model.dart';
import '../models/forgot_password_request_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/session_snapshot_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;
  final SessionSnapshotStorage _snapshotStorage;

  const AuthRepositoryImpl(
    this._remoteDataSource,
    this._tokenStorage,
    this._snapshotStorage,
  );

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      LoginRequestModel(email: email, password: password),
    );

    if (response.accessToken.isEmpty) {
      throw Exception('Access token is missing');
    }

    await _tokenStorage.saveAccessToken(response.accessToken);
    await _tokenStorage.saveRefreshToken(response.refreshToken);

    final entity = response.toEntity();
    final snapshot = SessionSnapshot(
      accountId: entity.accountId,
      email: entity.email,
      fullName: entity.fullName,
      accountType: entity.accountType,
    );
    await _snapshotStorage.saveSnapshot(snapshot);

    return entity;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _remoteDataSource.register(
      RegisterRequestModel(
        email: email,
        password: password,
        fullName: fullName,
      ),
    );
  }

  @override
  Future<void> confirmRegistration({
    required String email,
    required String otpCode,
  }) {
    return _remoteDataSource.confirmRegistration(
      ConfirmRegistrationRequestModel(email: email, otpCode: otpCode),
    );
  }

  @override
  Future<void> forgotPassword({required String email}) {
    return _remoteDataSource.forgotPassword(
      ForgotPasswordRequestModel(email: email),
    );
  }

  @override
  Future<void> confirmForgotPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) {
    return _remoteDataSource.confirmForgotPassword(
      ConfirmForgotPasswordRequestModel(
        email: email,
        otpCode: otpCode,
        newPassword: newPassword,
      ),
    );
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.clear();
    await _snapshotStorage.clearSnapshot();
  }

  @override
  Future<LoginResult?> restoreSession() async {
    final token = await _tokenStorage.getAccessToken();
    final snapshot = await _snapshotStorage.getSnapshot();

    if (token == null || token.isEmpty) {
      if (snapshot != null) {
        await _snapshotStorage.clearSnapshot();
      }
      return null;
    }

    if (snapshot == null) {
      await _tokenStorage.clear();
      return null;
    }

    return LoginResult(
      accountId: snapshot.accountId,
      email: snapshot.email,
      fullName: snapshot.fullName,
      phone: '',
      accountType: snapshot.accountType,
      accessToken: token,
      refreshToken: '',
    );
  }
}
