import '../entities/voice_order_recognition.dart';

abstract class VoiceOrderRepository {
  Future<VoiceOrderRecognition> recognizeAudioFile({
    required String audioFilePath,
    required int storeId,
  });
}
