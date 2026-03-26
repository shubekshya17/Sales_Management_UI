import 'package:flutter/material.dart';
import '../core/api_client.dart';

class PaymentDetailScreen extends StatefulWidget {
  final String paymentMethod;
  final DateTime fromDate;
  final DateTime toDate;

  const PaymentDetailScreen({
    super.key,
    required this.paymentMethod,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  List<Map<String, dynamic>>? _items;
  bool _isLoading = true;
  String? _errorMessage;

  // Table Column Definitions
  static const List<_ColDef> _columns = [
    _ColDef('#', 48),
    _ColDef('Date', 100),
    _ColDef('Invoice', 150),
    _ColDef('Party', 200),
    _ColDef('Gross', 70),
    _ColDef('Discount', 90),
    _ColDef('NetSale', 90),
    _ColDef('Vat', 70),
    _ColDef('Total', 90),
    _ColDef('TRNUser', 100),
    _ColDef('TRNTime', 70),
    _ColDef('STax', 70),
    _ColDef('Pax', 70),
    _ColDef('BillToPan', 100),
    _ColDef('BillToMob', 90),
    _ColDef('Cash', 100),
    _ColDef('CreditCard', 100),
    _ColDef('Credit', 100),
    _ColDef('Online', 100),
    _ColDef('GVoucher', 90),
    _ColDef('SalesReturnVoucher', 90),
    _ColDef('Complimentary', 90),
    _ColDef('TransactionId', 90),
    _ColDef('OrderMode', 90),
  ];

  double get _totalTableWidth =>
      _columns.fold(0.0, (sum, col) => sum + col.width);

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ApiClient.getSalesDetailPaymentMethodWise(
        fromDate: widget.fromDate,
        toDate: widget.toDate,
        paymentMethod: widget.paymentMethod,
      );
      setState(() {
        _items = data.map((e) => e as Map<String, dynamic>).toList();
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  String _formatAmount(dynamic value) {
    final amount = (value is num) ? value.toDouble() : 0.0;
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()}.${parts[1]}';
  }

  double _sum(String key) => (_items ?? []).fold(
    0.0,
    (s, item) => s + ((item[key] as num?)?.toDouble() ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.paymentMethod,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_formatDate(widget.fromDate.toIso8601String())} → ${_formatDate(widget.toDate.toIso8601String())}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A237E)),
            )
          : _errorMessage != null
          ? _ErrorState(message: _errorMessage!, onRetry: _fetchDetail)
          : _items == null || _items!.isEmpty
          ? Center(child: Text('No transactions for "${widget.paymentMethod}"'))
          : Column(
              children: [
                // --- EXACT DESIGN SUMMARY CARDS ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Net Sale',
                          amount: _formatAmount(_sum('netSale')),
                          icon: Icons.account_balance_wallet,
                          color: Colors.blue,
                          subtitle: 'Gross total',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Discount',
                          amount: _formatAmount(_sum('discount')),
                          icon: Icons.local_offer,
                          color: Colors.orange,
                          subtitle: 'Total disc',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          label: 'VAT',
                          amount: _formatAmount(_sum('vat')),
                          icon: Icons.receipt,
                          color: Colors.purple,
                          subtitle: 'Tax total',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Grand Total',
                          amount: _formatAmount(_sum('total')),
                          icon: Icons.payments,
                          color: Colors.green,
                          subtitle: 'Final amount',
                          isHighlighted: true,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- TABLE AREA ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _StickyTableView(
                        totalWidth: _totalTableWidth,
                        headerRow: _buildTableRow(
                          cells: _columns.map((c) => c.label).toList(),
                          isHeader: true,
                        ),
                        itemCount: _items!.length,
                        rowBuilder: (index) {
                          final item = _items![index];
                          return _buildTableRow(
                            isHeader: false,
                            isEven: index.isEven,
                            cells: [
                              '${index + 1}',
                              _formatDate(item['date']?.toString()),
                              item['invoice']?.toString() ?? '-',
                              item['party']?.toString() ?? '-',
                              _formatAmount(item['gross']),
                              _formatAmount(item['discount']),
                              _formatAmount(item['netSale']),
                              _formatAmount(item['vat']),
                              _formatAmount(item['total']),
                              item['trnUser']?.toString() ?? '-',
                              item['trnTime']?.toString() ?? '-',
                              _formatAmount(item['sTax']),
                              item['pax']?.toString() ?? '-',
                              item['billToPan']?.toString() ?? '-',
                              item['billToMob']?.toString() ?? '-',
                              _formatAmount(item['cash']),
                              _formatAmount(item['creditCard']),
                              _formatAmount(item['credit']),
                              _formatAmount(item['online']),
                              item['gVoucher']?.toString() ?? '-',
                              item['salesReturnVoucher']?.toString() ?? '-',
                              item['complimentary']?.toString() ?? '-',
                              item['transactionId']?.toString() ?? '-',
                              item['orderMode']?.toString() ?? '-',
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTableRow({
    required List<String> cells,
    required bool isHeader,
    bool isEven = false,
  }) {
    return Container(
      color: isHeader
          ? Colors.grey.shade100
          : (isEven ? Colors.white : Colors.grey.shade50),
      child: Row(
        children: List.generate(_columns.length, (i) {
          return SizedBox(
            width: _columns[i].width.toDouble(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Text(
                cells[i],
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isHeader || i == 15
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isHeader || i == 15
                      ? const Color(0xFF1A237E)
                      : Colors.black87,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Fixed Scroll Logic
class _StickyTableView extends StatelessWidget {
  final double totalWidth;
  final Widget headerRow;
  final int itemCount;
  final Widget Function(int index) rowBuilder;

  const _StickyTableView({
    required this.totalWidth,
    required this.headerRow,
    required this.itemCount,
    required this.rowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Column(
          children: [
            headerRow,
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) => rowBuilder(index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- EXACT DESIGN SUMMARY CARD WIDGET ---
class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool isHighlighted;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF1A237E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? const Color(0xFF1A237E) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isHighlighted ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.white.withOpacity(0.15)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isHighlighted ? Colors.white : color,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isHighlighted ? Colors.white60 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColDef {
  final String label;
  final int width;
  const _ColDef(this.label, this.width);
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          Text(message, style: const TextStyle(color: Colors.red)),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
