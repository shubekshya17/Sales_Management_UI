// screens/product_recipe_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api_client.dart';
import '../models/category_dropdown.dart';
import '../models/product_dropdown.dart';
import '../models/product_ingredient_dropdown.dart';
import '../models/recipe_ingredient.dart';

class ProductRecipeScreen extends StatefulWidget {
  const ProductRecipeScreen({super.key});

  @override
  State<ProductRecipeScreen> createState() => _ProductRecipeScreenState();
}

class _ProductRecipeScreenState extends State<ProductRecipeScreen> {
  // Loading states
  bool _isLoadingCategories = false;
  bool _isLoadingProducts = false;
  bool _isLoadingIngredients = false;

  // Data lists
  List<CategoryDropdown> _categories = [];
  List<ProductDropdown> _products = [];
  List<ProductIngredientDropdown> _allIngredients = [];

  // Selected values
  CategoryDropdown? _selectedCategory;
  ProductDropdown? _selectedProduct;
  List<RecipeIngredient> _selectedIngredients = [];

  // Error message
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadIngredients();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _errorMessage = null;
    });

    try {
      final categories = await ApiClient.getCategoryDropdown();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _errorMessage = 'Failed to load categories: $e';
      });
    }
  }

  Future<void> _loadIngredients() async {
    setState(() {
      _isLoadingIngredients = true;
    });

    try {
      final ingredients = await ApiClient.getProductIngredientDropdown();
      setState(() {
        _allIngredients = ingredients;
        _isLoadingIngredients = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingIngredients = false;
        _errorMessage = 'Failed to load ingredients: $e';
      });
    }
  }

  Future<void> _loadProductsByCategory(int categoryId) async {
    setState(() {
      _isLoadingProducts = true;
      _selectedProduct = null;
      _products = [];
      _selectedIngredients = [];
    });

    try {
      final products = await ApiClient.getProductDropdown(categoryId);
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
        _errorMessage = 'Failed to load products: $e';
      });
    }
  }

  void _onCategoryChanged(CategoryDropdown? category) {
    setState(() {
      _selectedCategory = category;
      _selectedProduct = null;
      _selectedIngredients = [];
    });

    if (category != null) {
      print("Selected Category ID: ${category.id}");
      _loadProductsByCategory(category.id);
    }
  }

  void _onProductChanged(ProductDropdown? product) {
    setState(() {
      _selectedProduct = product;
      _selectedIngredients = [];
    });
  }

  void _showIngredientPicker() {
    showDialog(
      context: context,
      builder: (context) => _IngredientPickerDialog(
        allIngredients: _allIngredients,
        selectedIngredients: _selectedIngredients,
        onConfirm: (selectedIngredients) {
          setState(() {
            _selectedIngredients = selectedIngredients;
          });
        },
      ),
    );
  }

  void _removeIngredient(int index) {
    setState(() {
      _selectedIngredients.removeAt(index);
    });
  }

  void _updateQuantity(int index, double quantity) {
    setState(() {
      _selectedIngredients[index].quantity = quantity;
    });
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Recipe Management',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Define ingredients and quantities for your products',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Category Dropdown
                      _FormLabel('Item Category'),
                      const SizedBox(height: 8),
                      _isLoadingCategories
                          ? const LinearProgressIndicator()
                          : _buildDropdown<CategoryDropdown>(
                              value: _selectedCategory,
                              items: _categories,
                              hint: 'Select a category',
                              displayText: (c) => c.categoryName,
                              onChanged: _onCategoryChanged,
                            ),

                      const SizedBox(height: 24),

                      // Product Dropdown
                      _FormLabel('Item Name'),
                      const SizedBox(height: 8),
                      _isLoadingProducts
                          ? const LinearProgressIndicator()
                          : _buildDropdown<ProductDropdown>(
                              value: _selectedProduct,
                              items: _products,
                              hint: _selectedCategory == null
                                  ? 'Select a category first'
                                  : 'Select a product',
                              displayText: (p) => p.name,
                              onChanged: _selectedCategory == null
                                  ? null
                                  : _onProductChanged,
                            ),

                      const SizedBox(height: 24),

                      // Ingredients Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _FormLabel('Ingredients'),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _selectedProduct == null
                                ? null
                                : _showIngredientPicker,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Ingredients'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Selected Ingredients List
                      if (_selectedIngredients.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                              _selectedProduct == null
                                  ? 'Select a product first to add ingredients'
                                  : 'No ingredients added yet',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      else
                        ..._selectedIngredients.asMap().entries.map((entry) {
                          final index = entry.key;
                          final recipeIngredient = entry.value;
                          return _IngredientCard(
                            recipeIngredient: recipeIngredient,
                            onQuantityChanged: (qty) =>
                                _updateQuantity(index, qty),
                            onRemove: () => _removeIngredient(index),
                          );
                        }).toList(),

                      const SizedBox(height: 32),

                      // Action Buttons (for later - save functionality)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = null;
                                _selectedProduct = null;
                                _selectedIngredients = [];
                                _products = [];
                              });
                            },
                            child: const Text('Clear'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _selectedIngredients.isEmpty
                                ? null
                                : () {
                                    // TODO: Save functionality in next step
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Saved')),
                                    );
                                  },
                            child: const Text('Save Recipe'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String hint,
    required String Function(T) displayText,
    required void Function(T?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: onChanged == null ? Colors.grey.shade100 : Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text(hint),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1A237E)),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(displayText(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Form Label Widget
class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    );
  }
}

// Ingredient Card Widget
class _IngredientCard extends StatefulWidget {
  final RecipeIngredient recipeIngredient;
  final Function(double) onQuantityChanged;
  final VoidCallback onRemove;

  const _IngredientCard({
    required this.recipeIngredient,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  State<_IngredientCard> createState() => _IngredientCardState();
}

class _IngredientCardState extends State<_IngredientCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.recipeIngredient.quantity.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ingredient name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipeIngredient.ingredient.ingredient,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unit: ${widget.recipeIngredient.ingredient.unit}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Quantity input
            Expanded(
              flex: 2,
              child: TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  final qty = double.tryParse(value) ?? 0;
                  widget.onQuantityChanged(qty);
                },
              ),
            ),

            const SizedBox(width: 12),

            // Remove button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: widget.onRemove,
              tooltip: 'Remove ingredient',
            ),
          ],
        ),
      ),
    );
  }
}

// Ingredient Picker Dialog
class _IngredientPickerDialog extends StatefulWidget {
  final List<ProductIngredientDropdown> allIngredients;
  final List<RecipeIngredient> selectedIngredients;
  final Function(List<RecipeIngredient>) onConfirm;

  const _IngredientPickerDialog({
    required this.allIngredients,
    required this.selectedIngredients,
    required this.onConfirm,
  });

  @override
  State<_IngredientPickerDialog> createState() =>
      _IngredientPickerDialogState();
}

class _IngredientPickerDialogState extends State<_IngredientPickerDialog> {
  late List<RecipeIngredient> _tempSelected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedIngredients);
  }

  List<ProductIngredientDropdown> get _filteredIngredients {
    if (_searchQuery.isEmpty) return widget.allIngredients;
    return widget.allIngredients
        .where(
          (i) =>
              i.ingredient.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  bool _isSelected(ProductIngredientDropdown ingredient) {
    return _tempSelected.any((r) => r.ingredient.id == ingredient.id);
  }

  void _toggleIngredient(ProductIngredientDropdown ingredient) {
    setState(() {
      if (_isSelected(ingredient)) {
        _tempSelected.removeWhere((r) => r.ingredient.id == ingredient.id);
      } else {
        _tempSelected.add(
          RecipeIngredient(ingredient: ingredient, quantity: 0),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Ingredients',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search ingredients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Selected count
            Text(
              '${_tempSelected.length} ingredient(s) selected',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),

            const SizedBox(height: 12),

            // Ingredients list
            Expanded(
              child: ListView.builder(
                itemCount: _filteredIngredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _filteredIngredients[index];
                  final isSelected = _isSelected(ingredient);

                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(ingredient.ingredient),
                    subtitle: Text(
                      'Unit: ${ingredient.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    activeColor: const Color(0xFF1A237E),
                    onChanged: (_) => _toggleIngredient(ingredient),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    widget.onConfirm(_tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
