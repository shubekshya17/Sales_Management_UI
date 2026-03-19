import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/category_range.dart';

class CategoryRangeScreen extends StatefulWidget {
  const CategoryRangeScreen({super.key});

  @override
  State<CategoryRangeScreen> createState() => _CategoryRangeScreenState();
}

class _CategoryRangeScreenState extends State<CategoryRangeScreen> {
  // Holds the list fetched from API
  List<CategoryRange> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Auto-load when screen opens
  }

  // ─── Fetch list from GET /api/categoryrange ───────────────────────────────
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final jsonList = await ApiClient.getCategoryRanges();
      setState(() {
        _categories = jsonList
            .map((e) => CategoryRange.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load categories: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── Open the create form dialog ──────────────────────────────────────────
  void _openCreateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must use Cancel or Save button
      builder: (context) => _CreateCategoryDialog(
        onCreated: () {
          // Refresh the list after successful creation
          _fetchCategories();
        },
      ),
    );
  }

  // ─── Build UI ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Page Header ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: title + subtitle
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Range',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage sales category ranges',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              // Right: Create button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Category'),
              ),
            ],
          ),
        ),

        // ── Content Area ──
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
    // Loading spinner
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error message
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_errorMessage!,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No categories yet',
              style: TextStyle(
                  fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Create Category" to add your first range',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Data table
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '${_categories.length} categor${_categories.length == 1 ? 'y' : 'ies'} found',
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const Divider(height: 1),

          // Scrollable table
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                      Colors.grey.shade50),
                  columnSpacing: 32,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Category Name')),
                    DataColumn(label: Text('Min Value')),
                    DataColumn(label: Text('Max Value')),
                    DataColumn(label: Text('Range Width')),
                  ],
                  rows: _categories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final cat = entry.value;
                    final rangeWidth = cat.maxValue - cat.minValue;

                    return DataRow(
                      // Alternating row colors
                      color: WidgetStateProperty.all(
                        index.isEven
                            ? Colors.white
                            : Colors.grey.shade50,
                      ),
                      cells: [
                        DataCell(Text(
                          '${index + 1}',
                          style: TextStyle(color: Colors.grey.shade600),
                        )),
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
                                cat.categoryName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(
                          cat.minValue.toStringAsFixed(2),
                          style: const TextStyle(
                              fontFamily: 'monospace'),
                        )),
                        DataCell(Text(
                          cat.maxValue.toStringAsFixed(2),
                          style: const TextStyle(
                              fontFamily: 'monospace'),
                        )),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              rangeWidth.toStringAsFixed(2),
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
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

  // Gives each row a distinct color dot
  Color _categoryColor(int index) {
    const colors = [
      Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.red, Colors.teal,
    ];
    return colors[index % colors.length];
  }
}

// ─── Create Category Dialog ────────────────────────────────────────────────
class _CreateCategoryDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const _CreateCategoryDialog({required this.onCreated});

  @override
  State<_CreateCategoryDialog> createState() =>
      _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  // Controls for the three form fields
  final _categoryNameController = TextEditingController();
  final _minValueController = TextEditingController();
  final _maxValueController = TextEditingController();

  // Form key — used to validate all fields at once
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  String? _apiError; // Shows overlap error from API

  @override
  void dispose() {
    // Always dispose controllers to free memory
    _categoryNameController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate all fields — if any fail, stop here
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _apiError = null;
    });

    try {
      final dto = CreateCategoryRangeDto(
        categoryName: _categoryNameController.text.trim(),
        minValue: double.parse(_minValueController.text.trim()),
        maxValue: double.parse(_maxValueController.text.trim()),
      );

      await ApiClient.createCategoryRange(dto.toJson());

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        widget.onCreated();          // Refresh parent list

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Your API throws "Range overlaps with existing category"
      // We catch that and show it in the form
      setState(() => _apiError = e.toString()
          .replaceAll('DioException [bad response]:', '')
          .trim());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480, // Fixed width for the dialog
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Dialog only as tall as needed
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Dialog Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Category Range',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Define a new sales category by setting a name and value range.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // ── Category Name Field ──
              TextFormField(
                controller: _categoryNameController,
                decoration: _inputDecoration(
                  label: 'Category Name',
                  hint: 'e.g. Bronze, Silver, Gold',
                  icon: Icons.label_outline,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Category name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Min and Max Value side by side ──
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minValueController,
                      decoration: _inputDecoration(
                        label: 'Min Value',
                        hint: 'e.g. 0',
                        icon: Icons.arrow_downward,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Must be a number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxValueController,
                      decoration: _inputDecoration(
                        label: 'Max Value',
                        hint: 'e.g. 1000',
                        icon: Icons.arrow_upward,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final max = double.tryParse(value.trim());
                        if (max == null) return 'Must be a number';

                        // Client-side check: max must be greater than min
                        final min = double.tryParse(
                            _minValueController.text.trim());
                        if (min != null && max <= min) {
                          return 'Must be > Min';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              // ── API Error (overlap) ──
              if (_apiError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _apiError!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ── Action Buttons ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  // Save button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
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

  // Reusable input decoration so all fields look consistent
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}