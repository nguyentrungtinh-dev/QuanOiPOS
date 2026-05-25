import '../entities/service_package.dart';

abstract class SubscriptionRepository {
  Future<List<ServicePackage>> loadPlans();
}
