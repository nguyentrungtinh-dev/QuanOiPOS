import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/recognize_voice_order_use_case.dart';
import '../providers/voice_order_providers.dart';
import '../services/voice_order_audio_recorder.dart';
import 'voice_order_state.dart';

class VoiceOrderNotifier extends AutoDisposeNotifier<VoiceOrderState> {
  late final RecognizeVoiceOrderUseCase _recognizeVoiceOrder;
  late final VoiceOrderAudioRecorder _audioRecorder;

  @override
  VoiceOrderState build() {
    _recognizeVoiceOrder = ref.read(recognizeVoiceOrderUseCaseProvider);
    _audioRecorder = ref.read(voiceOrderAudioRecorderProvider);
    ref.onDispose(() {
      _audioRecorder.cancel();
    });
    return const VoiceOrderState.idle();
  }

  Future<void> startRecording() async {
    if (state.isBusy || state.status == VoiceOrderStatus.recording) {
      return;
    }

    try {
      if (state.audioFilePath != null || state.recognition != null) {
        await _audioRecorder.cancel();
      }
      final audioFilePath = await _audioRecorder.start();
      state = VoiceOrderState(
        status: VoiceOrderStatus.recording,
        audioFilePath: audioFilePath,
      );
    } on VoiceOrderRecorderPermissionException catch (error) {
      state = VoiceOrderState(
        status: VoiceOrderStatus.permissionDenied,
        errorMessage: error.toString(),
      );
    } catch (error) {
      state = VoiceOrderState(
        status: VoiceOrderStatus.error,
        errorMessage: _errorMessage(error, 'Không thể bắt đầu ghi âm.'),
      );
    }
  }

  Future<void> stopRecording() async {
    if (state.status != VoiceOrderStatus.recording) {
      return;
    }

    try {
      final audioFilePath = await _audioRecorder.stop();
      state = VoiceOrderState(
        status: VoiceOrderStatus.readyToSend,
        audioFilePath: audioFilePath ?? state.audioFilePath,
        liveTranscript: state.liveTranscript,
        speechPreviewMessage: state.speechPreviewMessage,
      );
    } catch (error) {
      state = state.copyWith(
        status: VoiceOrderStatus.error,
        errorMessage: _errorMessage(error, 'Không thể dừng ghi âm.'),
      );
    }
  }

  Future<void> stopAndRecognize(int storeId) async {
    if (state.status != VoiceOrderStatus.recording) {
      return;
    }

    try {
      final audioFilePath = await _audioRecorder.stop();
      final pathToSend = audioFilePath ?? state.audioFilePath;
      if (pathToSend == null || pathToSend.trim().isEmpty) {
        state = state.copyWith(
          status: VoiceOrderStatus.error,
          errorMessage: 'Không tìm thấy file ghi âm.',
        );
        return;
      }

      state = VoiceOrderState(
        status: VoiceOrderStatus.recognizing,
        audioFilePath: pathToSend,
      );

      final recognition = await _recognizeVoiceOrder(
        audioFilePath: pathToSend,
        storeId: storeId,
      );
      state = VoiceOrderState(
        status: VoiceOrderStatus.success,
        audioFilePath: pathToSend,
        recognition: recognition,
      );
    } catch (error) {
      state = state.copyWith(
        status: VoiceOrderStatus.error,
        errorMessage: _errorMessage(
          error,
          'Không thể nhận diện đơn hàng bằng giọng nói.',
        ),
      );
    }
  }

  Future<void> recognize(int storeId) async {
    final audioFilePath = state.audioFilePath;
    if (audioFilePath == null || audioFilePath.trim().isEmpty || state.isBusy) {
      return;
    }

    state = state.copyWith(
      status: VoiceOrderStatus.recognizing,
      errorMessage: null,
    );

    try {
      final recognition = await _recognizeVoiceOrder(
        audioFilePath: audioFilePath,
        storeId: storeId,
      );
      state = VoiceOrderState(
        status: VoiceOrderStatus.success,
        audioFilePath: audioFilePath,
        recognition: recognition,
      );
    } catch (error) {
      state = state.copyWith(
        status: VoiceOrderStatus.error,
        errorMessage: _errorMessage(
          error,
          'Không thể nhận diện đơn hàng bằng giọng nói.',
        ),
      );
    }
  }

  Future<void> clear() async {
    await _audioRecorder.cancel();
    state = const VoiceOrderState.idle();
  }

  String _errorMessage(Object error, String fallback) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    return text.isEmpty ? fallback : text;
  }
}
