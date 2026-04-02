import 'package:flutter/material.dart';

enum NavItem {
  categoryRange,
  excelUpload,
  salesDetailReport,
  salesCollectionReport,
  product,
  productIngredient,
  productRecipe,
}

class Sidebar extends StatelessWidget {
  final NavItem selected;
  final ValueChanged<NavItem> onSelect;

  const Sidebar({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: const Color(0xFF1A237E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── App Title ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: const Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text(
                  'Sales Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 8),
          // ── Main Navigation ──
          _NavTile(
            icon: Icons.upload_file,
            label: 'Excel Upload',
            isSelected: selected == NavItem.excelUpload,
            onTap: () => onSelect(NavItem.excelUpload),
          ),
          _NavTile(
            icon: Icons.category,
            label: 'Category Range',
            isSelected: selected == NavItem.categoryRange,
            onTap: () => onSelect(NavItem.categoryRange),
          ),
          _NavTile(
            icon: Icons.inventory_2_rounded,
            label: 'Product',
            isSelected: selected == NavItem.product,
            onTap: () => onSelect(NavItem.product),
          ),
           _NavTile(
            icon: Icons.fastfood,
            label: 'Product Ingredients',
            isSelected: selected == NavItem.productIngredient,
            onTap: () => onSelect(NavItem.productIngredient),
          ),

          _NavTile(
            icon: Icons.menu_book_rounded,
            label: 'Product Recipe',
            isSelected: selected == NavItem.productRecipe,
            onTap: () => onSelect(NavItem.productRecipe),
          ),

          const SizedBox(height: 8),

          // ── Reports Section Header ──
          // This is just a label, not clickable
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'REPORTS',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const Divider(
            color: Colors.white24,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          const SizedBox(height: 4),

          // ── Report Items ──
          _NavTile(
            icon: Icons.receipt_long_rounded,
            label: 'Sales Detail Report',
            isSelected: selected == NavItem.salesDetailReport,
            onTap: () => onSelect(NavItem.salesDetailReport),
          ),
          _NavTile(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Sales Collection Report',
            isSelected: selected == NavItem.salesCollectionReport,
            onTap: () => onSelect(NavItem.salesCollectionReport),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white60,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
