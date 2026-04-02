class ProductIngredient {
  final int id;
  final String ingredient;
  final String unit;

  ProductIngredient({
    required this.id,
    required this.ingredient,
    required this.unit,
  });

  factory ProductIngredient.fromJson(Map<String, dynamic> json) {
    return ProductIngredient(
      id: json['id'] ?? 0,
      ingredient: json['ingredient'] ?? '',
      unit: json['unit'] ?? '',
    );
  }
}

class CreateProductIngredientDto {
  final String ingredient;
  final String unit;

  CreateProductIngredientDto({required this.ingredient, required this.unit});

  Map<String, dynamic> toJson() => {'ingredient': ingredient, 'unit': unit};
}
