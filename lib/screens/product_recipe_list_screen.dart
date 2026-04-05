// screens/product_recipe_list_screen.dart
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/product_recipe.dart';

class ProductRecipeListScreen extends StatefulWidget {
  const ProductRecipeListScreen({super.key});

  @override
  State<ProductRecipeListScreen> createState() =>
      _ProductRecipeListScreenState();
}

class _ProductRecipeListScreenState extends State<ProductRecipeListScreen> {
  List<ProductRecipe> _recipes = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recipes = await ApiClient.getAllProductRecipes();
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load recipes: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Recipes',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View and manage product recipes',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorWidget()
              : _recipes.isEmpty
              ? _buildEmptyWidget()
              : _buildRecipeTable(),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadRecipes, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No recipes found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeTable() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1A237E),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(60), // S.N
                    1: FlexColumnWidth(2), // Item Category
                    2: FlexColumnWidth(2), // Items Name
                    3: FlexColumnWidth(2.5), // Ingredients
                    4: FixedColumnWidth(100), // Quantity
                    5: FixedColumnWidth(100), // Unit
                  },
                  children: [
                    TableRow(
                      children: [
                        _buildHeaderCell('#'),
                        _buildHeaderCell('Item Category'),
                        _buildHeaderCell('Items Name'),
                        _buildHeaderCell('Ingredients'),
                        _buildHeaderCell('Quantity'),
                        _buildHeaderCell('Unit'),
                      ],
                    ),
                  ],
                ),
              ),

              // Table Body
              ..._buildTableRows(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  List<Widget> _buildTableRows() {
    List<Widget> rows = [];
    int serialNumber = 1;

    for (var recipe in _recipes) {
      if (recipe.ingredients.isEmpty) {
        // If no ingredients, show one row
        rows.add(
          _buildRecipeRow(
            serialNumber: serialNumber,
            recipe: recipe,
            ingredient: null,
            isFirst: true,
            isLast: true,
          ),
        );
        serialNumber++;
      } else {
        // For each ingredient, create a row
        for (int i = 0; i < recipe.ingredients.length; i++) {
          rows.add(
            _buildRecipeRow(
              serialNumber: serialNumber,
              recipe: recipe,
              ingredient: recipe.ingredients[i],
              isFirst: i == 0,
              isLast: i == recipe.ingredients.length - 1,
            ),
          );
        }
        serialNumber++;
      }
    }

    return rows;
  }

  Widget _buildRecipeRow({
    required int serialNumber,
    required ProductRecipe recipe,
    required RecipeIngredient? ingredient,
    required bool isFirst,
    required bool isLast,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.grey.shade300 : Colors.grey.shade200,
            width: isLast ? 1 : 0.5,
          ),
        ),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(60),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2.5),
          4: FixedColumnWidth(100),
          5: FixedColumnWidth(100),
        },
        children: [
          TableRow(
            children: [
              // Serial Number (only on first row)
              _buildDataCell(
                isFirst ? serialNumber.toString() : '',
                rowSpan: true,
              ),
              // Category (only on first row)
              _buildDataCell(isFirst ? recipe.categoryName : '', rowSpan: true),
              // Product Name (only on first row)
              _buildDataCell(isFirst ? recipe.productName : '', rowSpan: true),
              // Ingredient Name
              _buildDataCell(ingredient?.ingredientName ?? ''),
              // Quantity
              _buildDataCell(
                ingredient != null ? ingredient.quantity.toString() : '',
                isNumber: true,
              ),
              // Unit
              _buildDataCell(ingredient?.unitName ?? ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    bool rowSpan = false,
    bool isNumber = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: rowSpan ? FontWeight.w500 : FontWeight.normal,
        ),
        textAlign: isNumber ? TextAlign.right : TextAlign.left,
      ),
    );
  }
}
