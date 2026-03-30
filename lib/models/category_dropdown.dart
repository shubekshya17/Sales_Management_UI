class CategoryDropdown {
  final int id;
  final String categoryName;

  CategoryDropdown({required this.id, required this.categoryName});

  factory CategoryDropdown.fromJson(Map<String, dynamic> json) {
    return CategoryDropdown(
      id: json['id'] ?? 0,
      categoryName: json['categoryName'] ?? '',
    );
  }
}
