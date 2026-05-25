import '../../../../core/network/dio/dio_client.dart';
import '../models/service_package_model.dart';

class SubscriptionRemoteDataSource {
  final DioClient _dioClient;

  const SubscriptionRemoteDataSource(this._dioClient);

  Future<List<ServicePackageModel>> getSubscriptionPlans() async {
    final response = await _dioClient.getResponse<List<ServicePackageModel>>(
      '/subscription-plans',
      dataFromJson: ServicePackageModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Load subscription plans failed',
      );
    }

    return response.data!;
  }

  Never _throwRequestFailure(
    String? message,
    List<String> errors,
    String fallbackMessage,
  ) {
    throw Exception(
      message ?? (errors.isNotEmpty ? errors.first : fallbackMessage),
    );
  }
}
