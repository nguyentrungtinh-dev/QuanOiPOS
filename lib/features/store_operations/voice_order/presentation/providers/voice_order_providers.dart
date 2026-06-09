import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../data/datasources/voice_order_remote_data_source.dart';
import '../../domain/repositories/voice_order_repository.dart';
import '../../domain/usecases/recognize_voice_order_use_case.dart';
import '../controllers/voice_order_notifier.dart';
import '../controllers/voice_order_state.dart';
import '../services/voice_order_audio_recorder.dart';
import '../services/voice_order_speech_preview_service.dart';

final voiceOrderRemoteDataSourceProvider = Provider<VoiceOrderRemoteDataSource>(
  (ref) {
    return locator<VoiceOrderRemoteDataSource>();
  },
);

final voiceOrderRepositoryProvider = Provider<VoiceOrderRepository>((ref) {
  return locator<VoiceOrderRepository>();
});

final recognizeVoiceOrderUseCaseProvider = Provider<RecognizeVoiceOrderUseCase>(
  (ref) {
    return locator<RecognizeVoiceOrderUseCase>();
  },
);

final voiceOrderAudioRecorderProvider = Provider<VoiceOrderAudioRecorder>((
  ref,
) {
  return RecordVoiceOrderAudioRecorder();
});

final voiceOrderSpeechPreviewServiceProvider =
    Provider<VoiceOrderSpeechPreviewService>((ref) {
      return SpeechToTextVoiceOrderSpeechPreviewService();
    });

final voiceOrderNotifierProvider =
    NotifierProvider.autoDispose<VoiceOrderNotifier, VoiceOrderState>(
      VoiceOrderNotifier.new,
    );
