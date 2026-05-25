class ServicePackage {
  final String id;
  final String name;
  final double priceAmount;
  final int durationDays;
  final int maxStores;
  final int maxUsers;
  final List<String> features;
  final bool isActive;

  const ServicePackage({
    required this.id,
    required this.name,
    required this.priceAmount,
    required this.durationDays,
    required this.maxStores,
    required this.maxUsers,
    required this.features,
    required this.isActive,
  });
}
