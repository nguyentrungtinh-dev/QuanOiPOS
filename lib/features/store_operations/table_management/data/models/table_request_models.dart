class CreateTableRequestModel {
  final int storeId;
  final int areaId;
  final String name;
  final int capacity;

  const CreateTableRequestModel({
    required this.storeId,
    required this.areaId,
    required this.name,
    required this.capacity,
  });

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'areaId': areaId,
      'name': name,
      'capacity': capacity,
    };
  }
}

class UpdateTableRequestModel {
  final int areaId;
  final String name;
  final int capacity;

  const UpdateTableRequestModel({
    required this.areaId,
    required this.name,
    required this.capacity,
  });

  Map<String, dynamic> toJson() {
    return {'areaId': areaId, 'name': name, 'capacity': capacity};
  }
}
