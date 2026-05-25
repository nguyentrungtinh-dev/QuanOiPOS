import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../data/datasources/subscription_remote_data_source.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/usecases/load_subscription_plans_use_case.dart';
import '../controllers/subscription_notifier.dart';
import '../controllers/subscription_state.dart';

final subscriptionRemoteDataSourceProvider =
    Provider<SubscriptionRemoteDataSource>((ref) {
      return locator<SubscriptionRemoteDataSource>();
    });

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return locator<SubscriptionRepository>();
});

final loadSubscriptionPlansUseCaseProvider =
    Provider<LoadSubscriptionPlansUseCase>((ref) {
      return locator<LoadSubscriptionPlansUseCase>();
    });

final subscriptionNotifierProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(
      SubscriptionNotifier.new,
    );
