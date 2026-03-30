class ProductIngredientDropdown {
  final int id;
  final String ingredient;
  final String unit;

  ProductIngredientDropdown({
    required this.id,
    required this.ingredient,
    required this.unit,
  });

  factory ProductIngredientDropdown.fromJson(Map<String, dynamic> json) {
    return ProductIngredientDropdown(
      id: json['id'] ?? 0,
      ingredient: json['ingredient'] ?? '',
      unit: json['unit'] ?? '',
    );
  }
}
