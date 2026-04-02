import 'package:flutter/material.dart';
import 'package:sales_management_ui/core/api_client.dart';
import 'package:sales_management_ui/models/product_ingredient.dart';

class ProductIngredientListScreen extends StatefulWidget {
  const ProductIngredientListScreen({super.key});

  @override
  State<ProductIngredientListScreen> createState() =>
      _ProductIngredientListScreenState();
}

class _ProductIngredientListScreenState
    extends State<ProductIngredientListScreen> {
  List<ProductIngredient> _productIngredient = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProductIngredients();
  }

  Future<void> _fetchProductIngredients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final jsonList = await ApiClient.getProductIngredients();
      setState(() {
        _productIngredient = jsonList
            .map((e) => ProductIngredient.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load product ingredients: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreateProductIngredientDialog(
        onCreated: () {
          _fetchProductIngredients();
        },
      ),
    );
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
                    'Category Range',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage product ingredients',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Product Ingredient'),
              ),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_productIngredient.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No product ingredients yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Create Product Ingredient" to add your first ingredient',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '${_productIngredient.length} ingredient${_productIngredient.length == 1 ? '' : 's'} found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  columnSpacing: 32,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Ingredient')),
                    DataColumn(label: Text('Unit')),
                  ],
                  rows: _productIngredient.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return DataRow(
                      color: WidgetStateProperty.all(
                        index.isEven ? Colors.white : Colors.grey.shade50,
                      ),
                      cells: [
                        DataCell(
                          Text(
                            '${index + 1}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _categoryColor(index),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.ingredient,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(item.unit)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(int index) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}

// ─── CREATE DIALOG ────────────────────────────────────────────────

class _CreateProductIngredientDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const _CreateProductIngredientDialog({required this.onCreated});

  @override
  State<_CreateProductIngredientDialog> createState() =>
      _CreateProductIngredientDialogState();
}

class _CreateProductIngredientDialogState
    extends State<_CreateProductIngredientDialog> {
  final _ingredientController = TextEditingController();
  final _unitController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  String? _apiError;

  @override
  void dispose() {
    _ingredientController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _apiError = null;
    });

    try {
      final dto = {
        "ingredient": _ingredientController.text.trim(),
        "unit": _unitController.text.trim(),
      };

      await ApiClient.createProductIngredient(dto);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product ingredient created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _apiError = e.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Product Ingredient',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _ingredientController,
                decoration: _inputDecoration(
                  label: 'Ingredient',
                  hint: 'e.g. Swiss Momo',
                  icon: Icons.fastfood,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingredient is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _unitController,
                decoration: _inputDecoration(
                  label: 'Unit',
                  hint: 'e.g. gm, kg, pcs',
                  icon: Icons.scale,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unit is required';
                  }
                  return null;
                },
              ),

              if (_apiError != null) ...[
                const SizedBox(height: 16),
                Text(_apiError!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSubmitting ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
