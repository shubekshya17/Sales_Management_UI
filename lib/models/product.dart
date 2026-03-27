class Product {
  final int id;
  final String name;
  final String itemCode;

  Product({required this.id, required this.name, required this.itemCode});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      itemCode: json['itemCode'] ?? '',
    );
  }
}
