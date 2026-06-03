import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_subscription_purchase_model.dart';
import 'subscription_pending_purchase_storage.dart';

class SubscriptionPendingPurchaseStorageImpl
    implements SubscriptionPendingPurchaseStorage {
  static const _storageKey = 'subscription_pending_purchase';

  final SharedPreferences _preferences;

  const SubscriptionPendingPurchaseStorageImpl(this._preferences);

  @override
  Future<void> save(PendingSubscriptionPurchaseModel purchase) async {
    await _preferences.setString(_storageKey, purchase.toStorage());
  }

  @override
  Future<PendingSubscriptionPurchaseModel?> load() async {
    final value = _preferences.getString(_storageKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      return PendingSubscriptionPurchaseModel.fromStorage(value);
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_storageKey);
  }
}
