import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../data/datasources/subscription_remote_data_source.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/usecases/clear_pending_subscription_purchase_use_case.dart';
import '../../domain/usecases/load_active_subscription_use_case.dart';
import '../../domain/usecases/load_pending_subscription_purchase_use_case.dart';
import '../../domain/usecases/load_subscription_plans_use_case.dart';
import '../../domain/usecases/purchase_subscription_use_case.dart';
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

final loadActiveSubscriptionUseCaseProvider =
    Provider<LoadActiveSubscriptionUseCase>((ref) {
      return locator<LoadActiveSubscriptionUseCase>();
    });

final purchaseSubscriptionUseCaseProvider =
    Provider<PurchaseSubscriptionUseCase>((ref) {
      return locator<PurchaseSubscriptionUseCase>();
    });

final loadPendingSubscriptionPurchaseUseCaseProvider =
    Provider<LoadPendingSubscriptionPurchaseUseCase>((ref) {
      return locator<LoadPendingSubscriptionPurchaseUseCase>();
    });

final clearPendingSubscriptionPurchaseUseCaseProvider =
    Provider<ClearPendingSubscriptionPurchaseUseCase>((ref) {
      return locator<ClearPendingSubscriptionPurchaseUseCase>();
    });

final subscriptionNotifierProvider =
    NotifierProvider.autoDispose<SubscriptionNotifier, SubscriptionState>(
      SubscriptionNotifier.new,
    );
