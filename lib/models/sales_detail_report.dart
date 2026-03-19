// Matches CategoryWiseAmount from your API
class CategoryWiseAmount {
  final String categoryName;
  final double amount;

  CategoryWiseAmount({
    required this.categoryName,
    required this.amount,
  });

  factory CategoryWiseAmount.fromJson(Map<String, dynamic> json) {
    return CategoryWiseAmount(
      categoryName: json['categoryName'] ?? 'Uncategorized',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

// Matches SalesDetailReportResponse from your API
class SalesDetailReportResponse {
  final List<CategoryWiseAmount> categoryWiseAmount;
  final double netTotal;
  final double discount;
  final double vat;
  final double total;

  SalesDetailReportResponse({
    required this.categoryWiseAmount,
    required this.netTotal,
    required this.discount,
    required this.vat,
    required this.total,
  });

  factory SalesDetailReportResponse.fromJson(Map<String, dynamic> json) {
    return SalesDetailReportResponse(
      categoryWiseAmount: (json['categoryWiseAmount'] as List<dynamic>? ?? [])
          .map((e) => CategoryWiseAmount.fromJson(e as Map<String, dynamic>))
          .toList(),
      netTotal: (json['netTotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      vat: (json['vat'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}