import '../../domain/entities/voice_order_recognition.dart';
import '../../domain/repositories/voice_order_repository.dart';
import '../datasources/voice_order_remote_data_source.dart';

class VoiceOrderRepositoryImpl implements VoiceOrderRepository {
  final VoiceOrderRemoteDataSource _remoteDataSource;

  const VoiceOrderRepositoryImpl(this._remoteDataSource);

  @override
  Future<VoiceOrderRecognition> recognizeAudioFile({
    required String audioFilePath,
    required int storeId,
  }) async {
    final recognition = await _remoteDataSource.recognizeAudioFile(
      audioFilePath: audioFilePath,
      storeId: storeId,
    );
    return recognition.toEntity();
  }
}
