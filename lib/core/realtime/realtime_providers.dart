import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/injection.dart';
import 'realtime_notification_message.dart';
import 'realtime_notification_service.dart';

final realtimeNotificationServiceProvider =
    Provider<RealtimeNotificationService>((ref) {
      if (locator.isRegistered<RealtimeNotificationService>()) {
        return locator<RealtimeNotificationService>();
      }

      return const NoopRealtimeNotificationService();
    });

final realtimeNotificationStreamProvider =
    StreamProvider<RealtimeNotificationMessage>((ref) {
      return ref.watch(realtimeNotificationServiceProvider).messages;
    });
