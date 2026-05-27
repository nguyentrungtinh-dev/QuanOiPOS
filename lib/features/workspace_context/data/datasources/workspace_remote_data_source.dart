import '../../../../core/network/dio/dio_client.dart';
import '../models/store_model.dart';

class WorkspaceRemoteDataSource {
  final DioClient _dioClient;

  const WorkspaceRemoteDataSource(this._dioClient);

  Future<List<StoreModel>> getMyStores() async {
    final response = await _dioClient.getResponse<List<StoreModel>>(
      '/stores/my',
      dataFromJson: StoreModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Load my stores failed',
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
