import 'package:dio/dio.dart';

import '../../../../../core/env/env.dart';
import '../../../../../core/network/dio/dio_client.dart';
import '../models/voice_order_recognition_model.dart';

class VoiceOrderRemoteDataSource {
  final DioClient _dioClient;

  const VoiceOrderRemoteDataSource(this._dioClient);

  Future<VoiceOrderRecognitionModel> recognizeAudioFile({
    required String audioFilePath,
    required int storeId,
  }) async {
    final formData = FormData.fromMap({
      'store_id': storeId.toString(),
      'file': await MultipartFile.fromFile(
        audioFilePath,
        filename: 'voice-order.wav',
        contentType: DioMediaType('audio', 'wav'),
      ),
    });

    final response = await _dioClient.post<dynamic>(_asrUrl, data: formData);

    return VoiceOrderRecognitionModel.fromApiResponse(response.data);
  }

  String get _asrUrl {
    final baseUrl = Env.voiceApiBaseUrl;
    if (baseUrl.isEmpty) {
      throw const FormatException('VOICE_API_BASE_URL chua duoc cau hinh.');
    }

    return baseUrl.endsWith('/') ? '${baseUrl}asr' : '$baseUrl/asr';
  }
}
