import 'package:flutter/material.dart';
import 'package:sales_management_ui/screens/category_range_screen.dart';
import 'package:sales_management_ui/screens/excel_upload_screen.dart';
import 'package:sales_management_ui/screens/kot_screen.dart';
import 'package:sales_management_ui/screens/sales_detail_report_screen.dart';
import '../widgets/sidebar.dart';
import 'sales_collection_screen.dart';
import 'sales_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tracks which sidebar item is currently selected
  NavItem _selected = NavItem.salesCollection;

  // Returns the correct screen based on selection
  Widget _getScreen() {
    switch (_selected) {
      case NavItem.salesCollection:
        return const SalesCollectionScreen();
      case NavItem.salesDetail:
        return const SalesDetailScreen();
      case NavItem.kot:
        return const KotScreen();
      case NavItem.excelUpload:
        return const ExcelUploadScreen();
      case NavItem.categoryRange:
        return const CategoryRangeScreen();
      case NavItem.salesDetailReport:
        return const SalesDetailReportScreen();
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
          Expanded(
            child: _getScreen(),
          ),
        ],
      ),
    );
  }
}