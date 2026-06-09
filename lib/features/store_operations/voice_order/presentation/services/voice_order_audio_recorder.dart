import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

abstract class VoiceOrderAudioRecorder {
  Future<String> start();

  Future<String?> stop();

  Future<void> cancel();
}

class VoiceOrderRecorderPermissionException implements Exception {
  const VoiceOrderRecorderPermissionException();

  @override
  String toString() {
    return 'Ứng dụng cần quyền microphone để ghi âm đơn hàng.';
  }
}

class VoiceOrderRecorderException implements Exception {
  final String message;

  const VoiceOrderRecorderException(this.message);

  @override
  String toString() => message;
}

class RecordVoiceOrderAudioRecorder implements VoiceOrderAudioRecorder {
  final AudioRecorder _recorder;
  String? _currentPath;
  String? _lastPath;

  RecordVoiceOrderAudioRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  @override
  Future<String> start() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      throw const VoiceOrderRecorderPermissionException();
    }

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/voice_order_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
        autoGain: true,
      ),
      path: filePath,
    );

    _currentPath = filePath;
    _lastPath = filePath;
    return filePath;
  }

  @override
  Future<String?> stop() async {
    if (_currentPath == null) {
      return null;
    }

    final stoppedPath = await _recorder.stop();
    _currentPath = null;

    if (stoppedPath == null || stoppedPath.isEmpty) {
      throw const VoiceOrderRecorderException('Không thể dừng ghi âm.');
    }

    final file = File(stoppedPath);
    if (!await file.exists() || await file.length() <= 44) {
      throw const VoiceOrderRecorderException(
        'File ghi âm rỗng. Vui lòng thử lại và nói rõ hơn.',
      );
    }

    return stoppedPath;
  }

  @override
  Future<void> cancel() async {
    final filePath = _currentPath;
    if (filePath != null) {
      await _recorder.cancel();
    }

    final pathToDelete = filePath ?? _lastPath;
    if (pathToDelete != null) {
      final file = File(pathToDelete);
      if (await file.exists()) {
        await file.delete();
      }
    }

    _currentPath = null;
    _lastPath = null;
  }
}
