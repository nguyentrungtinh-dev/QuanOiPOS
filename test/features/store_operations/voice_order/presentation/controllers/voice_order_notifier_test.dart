import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/entities/unmatched_voice_order_item.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/entities/voice_order_item.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/entities/voice_order_recognition.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/repositories/voice_order_repository.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/usecases/recognize_voice_order_use_case.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/controllers/voice_order_state.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/providers/voice_order_providers.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/services/voice_order_audio_recorder.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/services/voice_order_speech_preview_service.dart';

void main() {
  test('records, releases, and recognizes voice order', () async {
    final repository = _FakeVoiceOrderRepository(
      recognition: _recognition(unmatched: true),
    );
    final recorder = _FakeVoiceOrderAudioRecorder();
    final speechPreview = _FakeVoiceOrderSpeechPreviewService(
      transcript: 'mot tra sua',
    );
    final container = _container(
      repository: repository,
      recorder: recorder,
      speechPreview: speechPreview,
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      voiceOrderNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final notifier = container.read(voiceOrderNotifierProvider.notifier);

    await notifier.startRecording();
    expect(
      container.read(voiceOrderNotifierProvider).status,
      VoiceOrderStatus.recording,
    );
    expect(recorder.startCallCount, 1);
    expect(speechPreview.startCallCount, 0);
    expect(container.read(voiceOrderNotifierProvider).liveTranscript, isEmpty);

    await notifier.stopAndRecognize(5);
    expect(speechPreview.stopCallCount, 0);

    final state = container.read(voiceOrderNotifierProvider);
    expect(state.status, VoiceOrderStatus.success);
    expect(state.recognition?.items.single.productName, 'Tra sua');
    expect(state.recognition?.unmatchedItems.single.rawText, 'tra dao');
    expect(repository.recognizedAudioPath, recorder.path);
    expect(repository.recognizedStoreId, 5);
  });

  test('permission denial sets permissionDenied state', () async {
    final container = _container(
      repository: _FakeVoiceOrderRepository(recognition: _recognition()),
      recorder: _FakeVoiceOrderAudioRecorder(
        startError: const VoiceOrderRecorderPermissionException(),
      ),
      speechPreview: _FakeVoiceOrderSpeechPreviewService(),
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      voiceOrderNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(voiceOrderNotifierProvider.notifier).startRecording();

    final state = container.read(voiceOrderNotifierProvider);
    expect(state.status, VoiceOrderStatus.permissionDenied);
    expect(state.errorMessage, contains('microphone'));
  });

  test('recognition error keeps audio and exposes error state', () async {
    final repository = _FakeVoiceOrderRepository(
      recognitionError: Exception('Backend down'),
    );
    final recorder = _FakeVoiceOrderAudioRecorder();
    final container = _container(
      repository: repository,
      recorder: recorder,
      speechPreview: _FakeVoiceOrderSpeechPreviewService(),
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      voiceOrderNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final notifier = container.read(voiceOrderNotifierProvider.notifier);
    await notifier.startRecording();
    await notifier.stopAndRecognize(5);

    final state = container.read(voiceOrderNotifierProvider);
    expect(state.status, VoiceOrderStatus.error);
    expect(state.audioFilePath, recorder.path);
    expect(state.errorMessage, 'Backend down');
  });

  test('clear cancels recorder only', () async {
    final recorder = _FakeVoiceOrderAudioRecorder();
    final speechPreview = _FakeVoiceOrderSpeechPreviewService();
    final container = _container(
      repository: _FakeVoiceOrderRepository(recognition: _recognition()),
      recorder: recorder,
      speechPreview: speechPreview,
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      voiceOrderNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final notifier = container.read(voiceOrderNotifierProvider.notifier);
    await notifier.startRecording();
    await notifier.clear();

    expect(
      container.read(voiceOrderNotifierProvider).status,
      VoiceOrderStatus.idle,
    );
    expect(recorder.cancelCallCount, 1);
    expect(speechPreview.cancelCallCount, 0);
  });
}

ProviderContainer _container({
  required _FakeVoiceOrderRepository repository,
  required _FakeVoiceOrderAudioRecorder recorder,
  required _FakeVoiceOrderSpeechPreviewService speechPreview,
}) {
  return ProviderContainer(
    overrides: [
      recognizeVoiceOrderUseCaseProvider.overrideWithValue(
        RecognizeVoiceOrderUseCase(repository),
      ),
      voiceOrderAudioRecorderProvider.overrideWithValue(recorder),
      voiceOrderSpeechPreviewServiceProvider.overrideWithValue(speechPreview),
    ],
  );
}

VoiceOrderRecognition _recognition({bool unmatched = false}) {
  return VoiceOrderRecognition(
    transcript: 'Cho toi 1 tra sua',
    validationSucceeded: !unmatched,
    validationMessage: unmatched
        ? 'Order voice chua hop le.'
        : 'Order voice hop le.',
    errors: unmatched ? const ['Product not found in database'] : const [],
    tableId: 3,
    tableName: 'Ban 3',
    tableStatus: 'Available',
    items: const [
      VoiceOrderItem(
        productId: 1,
        productName: 'Tra sua',
        quantity: 1,
        available: true,
      ),
    ],
    unmatchedItems: unmatched
        ? const [
            UnmatchedVoiceOrderItem(
              rawText: 'tra dao',
              quantity: 2,
              reason: 'Product not found in database',
            ),
          ]
        : const [],
  );
}

class _FakeVoiceOrderRepository implements VoiceOrderRepository {
  final VoiceOrderRecognition? recognition;
  final Exception? recognitionError;
  String? recognizedAudioPath;
  int? recognizedStoreId;

  _FakeVoiceOrderRepository({this.recognition, this.recognitionError});

  @override
  Future<VoiceOrderRecognition> recognizeAudioFile({
    required String audioFilePath,
    required int storeId,
  }) async {
    recognizedAudioPath = audioFilePath;
    recognizedStoreId = storeId;
    final error = recognitionError;
    if (error != null) {
      throw error;
    }

    return recognition!;
  }
}

class _FakeVoiceOrderAudioRecorder implements VoiceOrderAudioRecorder {
  final Object? startError;
  final String path = '/tmp/voice-order.wav';
  int startCallCount = 0;
  int cancelCallCount = 0;

  _FakeVoiceOrderAudioRecorder({this.startError});

  @override
  Future<String> start() async {
    startCallCount += 1;
    final error = startError;
    if (error != null) {
      throw error;
    }

    return path;
  }

  @override
  Future<String?> stop() async {
    return path;
  }

  @override
  Future<void> cancel() async {
    cancelCallCount += 1;
  }
}

class _FakeVoiceOrderSpeechPreviewService
    implements VoiceOrderSpeechPreviewService {
  final String? transcript;
  int startCallCount = 0;
  int stopCallCount = 0;
  int cancelCallCount = 0;

  _FakeVoiceOrderSpeechPreviewService({this.transcript});

  @override
  Future<void> start({
    required void Function(String transcript) onTranscript,
    required void Function(String message) onUnavailable,
  }) async {
    startCallCount += 1;
    final text = transcript;
    if (text != null) {
      onTranscript(text);
    }
  }

  @override
  Future<void> stop() async {
    stopCallCount += 1;
  }

  @override
  Future<void> cancel() async {
    cancelCallCount += 1;
  }
}
