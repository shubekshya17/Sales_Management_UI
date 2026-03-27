import 'package:flutter/material.dart';
import 'package:sales_management_ui/models/product.dart';
import '../core/api_client.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _nameSearchController = TextEditingController();
  final TextEditingController _codeSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _nameSearchController.addListener(_onSearchChanged);
    _codeSearchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _nameSearchController.dispose();
    _codeSearchController.dispose();
    super.dispose();
  }

  // ─── Filter by name AND item code independently ───────────────────────────
  void _onSearchChanged() {
    final nameQuery = _nameSearchController.text.trim().toLowerCase();
    final codeQuery = _codeSearchController.text.trim().toLowerCase();

    setState(() {
      _filtered = _products.where((p) {
        final matchesName =
            nameQuery.isEmpty || p.name.toLowerCase().contains(nameQuery);
        final matchesCode =
            codeQuery.isEmpty || p.itemCode.toLowerCase().contains(codeQuery);
        return matchesName && matchesCode;
      }).toList();
    });
  }

  // ─── Fetch list from GET /api/products ───────────────────────────────────
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final jsonList = await ApiClient.getProductList();
      final products = jsonList
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _products = products;
        _filtered = List.from(products);
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── Reusable small search field ─────────────────────────────────────────
  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
  }) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    controller.clear();
                    _onSearchChanged();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─── Build UI ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Page Header (matches CategoryRangeScreen) ──
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
                    'Products',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage your product catalogue',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              // Right: two compact search bars side by side
              Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: _buildSearchField(
                      controller: _nameSearchController,
                      hint: 'Search by name…',
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 200,
                    child: _buildSearchField(
                      controller: _codeSearchController,
                      hint: 'Search by item code…',
                    ),
                  ),
                ],
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

  // ─── Main content ─────────────────────────────────────────────────────────
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No products yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first product to get started.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _nameSearchController.clear();
                _codeSearchController.clear();
              },
              child: const Text('Clear search'),
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
              '${_filtered.length} product${_filtered.length == 1 ? '' : 's'} found',
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
                    DataColumn(label: Text('Product Name')),
                    DataColumn(label: Text('Item Code')),
                  ],
                  rows: _filtered.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;

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
                                  color: _rowColor(index),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            product.itemCode,
                            style: const TextStyle(fontFamily: 'monospace'),
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

  Color _rowColor(int index) {
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
