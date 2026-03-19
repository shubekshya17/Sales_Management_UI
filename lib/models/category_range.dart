class CategoryRange {
  final int id;
  final double minValue;
  final double maxValue;
  final String categoryName;

  CategoryRange({
    required this.id,
    required this.minValue,
    required this.maxValue,
    required this.categoryName,
  });

  factory CategoryRange.fromJson(Map<String, dynamic> json) {
    return CategoryRange(
      id: json['id'] ?? 0,
      minValue: (json['minValue'] ?? 0).toDouble(),
      maxValue: (json['maxValue'] ?? 0).toDouble(),
      categoryName: json['categoryName'] ?? '',
    );
  }
}

class CreateCategoryRangeDto {
  final double minValue;
  final double maxValue;
  final String categoryName;

  CreateCategoryRangeDto({
    required this.minValue,
    required this.maxValue,
    required this.categoryName,
  });

  Map<String, dynamic> toJson() => {
    'minValue': minValue,
    'maxValue': maxValue,
    'categoryName': categoryName,
  };
}