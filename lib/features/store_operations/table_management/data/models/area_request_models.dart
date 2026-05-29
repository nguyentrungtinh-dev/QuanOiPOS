class CreateAreaRequestModel {
  final int storeId;
  final String name;
  final String description;

  const CreateAreaRequestModel({
    required this.storeId,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {'storeId': storeId, 'name': name, 'description': description};
  }
}

class UpdateAreaRequestModel {
  final String name;
  final String description;

  const UpdateAreaRequestModel({required this.name, required this.description});

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description};
  }
}

class UpdateAreaDisplayOrderRequestModel {
  final int displayOrder;

  const UpdateAreaDisplayOrderRequestModel({required this.displayOrder});

  Map<String, dynamic> toJson() {
    return {'displayOrder': displayOrder};
  }
}
