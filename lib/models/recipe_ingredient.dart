import 'package:sales_management_ui/models/product_ingredient_dropdown.dart';

class RecipeIngredient {
  final ProductIngredientDropdown ingredient;
  double quantity;

  RecipeIngredient({required this.ingredient, required this.quantity});

  // Optional: Convert to JSON (for API later)
  Map<String, dynamic> toJson() {
    return {'ingredientId': ingredient.id, 'quantity': quantity};
  }
}
