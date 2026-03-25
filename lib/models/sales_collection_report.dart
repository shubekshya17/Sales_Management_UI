class AmountCalculation {
  final double totalCash;
  final double totalCreditCard;
  final double totalOnline;
  final double totalCredit;

  const AmountCalculation({
    required this.totalCash,
    required this.totalCreditCard,
    required this.totalOnline,
    required this.totalCredit,
  });

  factory AmountCalculation.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AmountCalculation(
        totalCash: 0,
        totalCreditCard: 0,
        totalOnline: 0,
        totalCredit: 0,
      );
    }
    return AmountCalculation(
      totalCash: (json['totalCash'] as num?)?.toDouble() ?? 0,
      totalCreditCard: (json['totalCreditCard'] as num?)?.toDouble() ?? 0,
      totalOnline: (json['totalOnline'] as num?)?.toDouble() ?? 0,
      totalCredit: (json['totalCredit'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SalesCollectionReportResponse {
  final AmountCalculation amountCalculation;
  final double netTotal;
  final double discount;
  final double vat;
  final double total;

  const SalesCollectionReportResponse({
    required this.amountCalculation,
    required this.netTotal,
    required this.discount,
    required this.vat,
    required this.total,
  });

  factory SalesCollectionReportResponse.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return SalesCollectionReportResponse(
        amountCalculation: AmountCalculation.fromJson(null),
        netTotal: 0,
        discount: 0,
        vat: 0,
        total: 0,
      );
    }
    return SalesCollectionReportResponse(
      amountCalculation: AmountCalculation.fromJson(
        json['amountCalculation'] as Map<String, dynamic>?,
      ),
      netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      vat: (json['vat'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}