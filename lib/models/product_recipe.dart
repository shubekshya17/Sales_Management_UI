// models/product_recipe.dart
class ProductRecipe {
  final int id;
  final int categoryId;
  final String categoryName;
  final int productId;
  final String productName;
  final List<RecipeIngredient> ingredients;
  final DateTime createdAt;

  ProductRecipe({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.productId,
    required this.productName,
    required this.ingredients,
    required this.createdAt,
  });

  factory ProductRecipe.fromJson(Map<String, dynamic> json) {
    return ProductRecipe(
      id: json['id'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      productId: json['productId'],
      productName: json['productName'],
      ingredients: (json['ingredients'] as List)
          .map((i) => RecipeIngredient.fromJson(i))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'productId': productId,
      'productName': productName,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class RecipeIngredient {
  final int productRecipeDetailId;
  final int productIngredientId;
  final String ingredientName;
  final String unitName;
  final double quantity;

  RecipeIngredient({
    required this.productRecipeDetailId,
    required this.productIngredientId,
    required this.ingredientName,
    required this.unitName,
    required this.quantity,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      productRecipeDetailId: json['productRecipeDetailId'],
      productIngredientId: json['productIngredientId'],
      ingredientName: json['ingredientName'],
      unitName: json['unitName'],
      quantity: (json['quantity'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productRecipeDetailId': productRecipeDetailId,
      'productIngredientId': productIngredientId,
      'ingredientName': ingredientName,
      'unitName': unitName,
      'quantity': quantity,
    };
  }
}