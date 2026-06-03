import 'dart:async';

import 'package:logger/logger.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../env/env.dart';
import '../storage/token_storage.dart';
import 'realtime_notification_message.dart';
import 'realtime_notification_service.dart';

class SignalRRealtimeNotificationService
    implements RealtimeNotificationService {
  final TokenStorage _tokenStorage;
  final Logger _logger;
  final String _hubUrl;

  final StreamController<RealtimeNotificationMessage> _messagesController =
      StreamController<RealtimeNotificationMessage>.broadcast();

  HubConnection? _connection;
  bool _isStarting = false;
  bool _isStarted = false;

  SignalRRealtimeNotificationService({
    required TokenStorage tokenStorage,
    required Logger logger,
    String? hubUrl,
  }) : _tokenStorage = tokenStorage,
       _logger = logger,
       _hubUrl = hubUrl ?? Env.notificationsHubUrl;

  @override
  Stream<RealtimeNotificationMessage> get messages =>
      _messagesController.stream;

  @override
  Future<void> start() async {
    if (_isStarted || _isStarting || _hubUrl.isEmpty) {
      return;
    }

    _isStarting = true;
    try {
      final connection = _connection ?? _buildConnection();
      _connection = connection;
      await connection.start();
      _isStarted = true;
    } catch (error) {
      _logger.w('SignalR notification hub connection failed: $error');
    } finally {
      _isStarting = false;
    }
  }

  @override
  Future<void> stop() async {
    final connection = _connection;
    _isStarted = false;
    _isStarting = false;

    if (connection == null) {
      return;
    }

    try {
      await connection.stop();
    } catch (error) {
      _logger.w('SignalR notification hub stop failed: $error');
    }
  }

  @override
  Future<void> restart() async {
    await stop();
    _connection = null;
    await start();
  }

  Future<void> dispose() async {
    await stop();
    await _messagesController.close();
  }

  HubConnection _buildConnection() {
    final connection = HubConnectionBuilder()
        .withUrl(
          _hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async =>
                await _tokenStorage.getAccessToken() ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    connection.on('ReceiveNotification', _handleReceiveNotification);
    connection.onclose(({error}) {
      _isStarted = false;
      if (error != null) {
        _logger.w('SignalR notification hub closed: $error');
      }
    });

    return connection;
  }

  void _handleReceiveNotification(List<Object?>? arguments) {
    final raw = arguments == null || arguments.isEmpty ? null : arguments.first;

    try {
      final message = RealtimeNotificationMessage.fromJson(raw);
      _messagesController.add(message);
    } catch (error) {
      _logger.w('Invalid realtime notification payload: $error');
    }
  }
}
