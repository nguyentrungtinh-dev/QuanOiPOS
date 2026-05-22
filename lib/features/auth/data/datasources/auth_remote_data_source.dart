import '../../../../core/network/dio/dio_client.dart';
import '../models/confirm_forgot_password_request_model.dart';
import '../models/confirm_registration_request_model.dart';
import '../models/forgot_password_request_model.dart';
import '../models/login_request_model.dart';
import '../models/login_response_data_model.dart';
import '../models/register_request_model.dart';

class AuthRemoteDataSource {
  final DioClient _dioClient;

  const AuthRemoteDataSource(this._dioClient);

  Future<LoginResponseDataModel> login(LoginRequestModel request) async {
    final response = await _dioClient.postResponse<LoginResponseDataModel>(
      '/auth/login',
      data: request.toJson(),
      dataFromJson: LoginResponseDataModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      final message =
          response.message ??
          (response.errors.isNotEmpty ? response.errors.first : 'Login failed');
      throw Exception(message);
    }

    return response.data!;
  }

  Future<void> register(RegisterRequestModel request) async {
    final response = await _dioClient.postResponse<Object?>(
      '/auth/register',
      data: request.toJson(),
    );

    _throwIfFailed(
      response.succeeded,
      response.message,
      response.errors,
      'Register failed',
    );
  }

  Future<void> confirmRegistration(
    ConfirmRegistrationRequestModel request,
  ) async {
    final response = await _dioClient.postResponse<Object?>(
      '/auth/register/confirm',
      data: request.toJson(),
    );

    _throwIfFailed(
      response.succeeded,
      response.message,
      response.errors,
      'Registration confirmation failed',
    );
  }

  Future<void> forgotPassword(ForgotPasswordRequestModel request) async {
    final response = await _dioClient.postResponse<Object?>(
      '/auth/forgot-password',
      data: request.toJson(),
    );

    _throwIfFailed(
      response.succeeded,
      response.message,
      response.errors,
      'Forgot password request failed',
    );
  }

  Future<void> confirmForgotPassword(
    ConfirmForgotPasswordRequestModel request,
  ) async {
    final response = await _dioClient.postResponse<Object?>(
      '/auth/forgot-password/confirm',
      data: request.toJson(),
    );

    _throwIfFailed(
      response.succeeded,
      response.message,
      response.errors,
      'Forgot password confirmation failed',
    );
  }

  void _throwIfFailed(
    bool succeeded,
    String? message,
    List<String> errors,
    String fallbackMessage,
  ) {
    if (succeeded) {
      return;
    }

    throw Exception(
      message ?? (errors.isNotEmpty ? errors.first : fallbackMessage),
    );
  }
}
