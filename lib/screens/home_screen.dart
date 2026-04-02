import 'package:flutter/material.dart';
import 'package:sales_management_ui/screens/category_range_screen.dart';
import 'package:sales_management_ui/screens/excel_upload_screen.dart';
import 'package:sales_management_ui/screens/product_ingredient_list_screen.dart';
import 'package:sales_management_ui/screens/product_ingredients_screen.dart';
import 'package:sales_management_ui/screens/product_screen.dart';
import 'package:sales_management_ui/screens/sales_collection_report_screen.dart';
import 'package:sales_management_ui/screens/sales_detail_report_screen.dart';
import '../widgets/sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tracks which sidebar item is currently selected
  NavItem _selected = NavItem.excelUpload;

  // Returns the correct screen based on selection
  Widget _getScreen() {
    switch (_selected) {
      case NavItem.excelUpload:
        return const ExcelUploadScreen();
      case NavItem.categoryRange:
        return const CategoryRangeScreen();
      case NavItem.salesDetailReport:
        return const SalesDetailReportScreen();
      case NavItem.salesCollectionReport:
        return const SalesCollectionReportScreen();
      case NavItem.product:
        return const ProductScreen();
      case NavItem.productIngredient:
        return const ProductIngredientListScreen();
      case NavItem.productRecipe:
        return const ProductRecipeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar on the left
          Sidebar(
            selected: _selected,
            onSelect: (item) => setState(() => _selected = item),
          ),
          // Main content on the right — expands to fill remaining space
          Expanded(child: _getScreen()),
        ],
      ),
    );
  }
}
