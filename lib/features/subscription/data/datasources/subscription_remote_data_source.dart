import '../../../../core/network/dio/dio_client.dart';
import '../models/active_subscription_model.dart';
import '../models/purchase_subscription_request_model.dart';
import '../models/purchase_subscription_result_model.dart';
import '../models/service_package_model.dart';

class SubscriptionRemoteDataSource {
  final DioClient _dioClient;

  const SubscriptionRemoteDataSource(this._dioClient);

  Future<List<ServicePackageModel>> getSubscriptionPlans() async {
    final response = await _dioClient.getResponse<List<ServicePackageModel>>(
      '/subscription-plans/active',
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

  Future<ActiveSubscriptionModel?> getActiveSubscription() async {
    final response = await _dioClient.getResponse<ActiveSubscriptionModel?>(
      '/subscriptions/active',
      dataFromJson: (json) =>
          json == null ? null : ActiveSubscriptionModel.fromJson(json),
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Load active subscription failed',
      );
    }

    return response.data;
  }

  Future<PurchaseSubscriptionResultModel> purchaseSubscription(
    PurchaseSubscriptionRequestModel request,
  ) async {
    final response = await _dioClient
        .postResponse<PurchaseSubscriptionResultModel>(
          '/subscriptions/purchase',
          data: request.toJson(),
          dataFromJson: PurchaseSubscriptionResultModel.fromJson,
        );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Purchase subscription failed',
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
