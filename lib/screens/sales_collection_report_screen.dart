import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/sales_collection_report.dart';
import 'payment_detail_screen.dart'; // ← new detail page (create this next)

class SalesCollectionReportScreen extends StatefulWidget {
  const SalesCollectionReportScreen({super.key});

  @override
  State<SalesCollectionReportScreen> createState() =>
      _SalesCollectionReportScreenState();
}

class _SalesCollectionReportScreenState
    extends State<SalesCollectionReportScreen> {
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();

  SalesCollectionReportResponse? _report;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final json = await ApiClient.getSalesCollectionReport(
        fromDate: _fromDate,
        toDate: _toDate,
      );
      setState(() {
        _report = SalesCollectionReportResponse.fromJson(json);
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to generate report: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1A237E)),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
      } else {
        _toDate = picked;
      }
    });
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()}.$decPart';
  }

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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sales Collection Report',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Tap a payment method to view its transactions',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateFilterCard(
                  fromDate: _fromDate,
                  toDate: _toDate,
                  isLoading: _isLoading,
                  onFromTap: () => _pickDate(isFrom: true),
                  onToTap: () => _pickDate(isFrom: false),
                  onGenerate: _generateReport,
                  formatDate: _formatDate,
                ),

                const SizedBox(height: 24),

                if (_errorMessage != null)
                  _ErrorBanner(message: _errorMessage!),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: Color(0xFF1A237E)),
                    ),
                  ),

                if (_report != null && !_isLoading) ...[
                  _SummaryCardsRow(
                    report: _report!,
                    formatAmount: _formatAmount,
                  ),
                  const SizedBox(height: 24),
                  // ── Pass fromDate & toDate into the table ──
                  _PaymentMethodTable(
                    report: _report!,
                    formatAmount: _formatAmount,
                    fromDate: _fromDate, // ← fix: was missing
                    toDate: _toDate,     // ← fix: was missing
                  ),
                ],

                if (_report == null && !_isLoading && _errorMessage == null)
                  _EmptyState(onGenerate: _generateReport),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Date Filter Card ──────────────────────────────────────────────────────
class _DateFilterCard extends StatelessWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final bool isLoading;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onGenerate;
  final String Function(DateTime) formatDate;

  const _DateFilterCard({
    required this.fromDate,
    required this.toDate,
    required this.isLoading,
    required this.onFromTap,
    required this.onToTap,
    required this.onGenerate,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: Color(0xFF1A237E), size: 22),
            const SizedBox(width: 12),
            const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 16),
            _DateButton(label: 'From', date: formatDate(fromDate), onTap: onFromTap),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
            ),
            _DateButton(label: 'To', date: formatDate(toDate), onTap: onToTap),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isLoading ? null : onGenerate,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(isLoading ? 'Generating...' : 'Generate Report'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _DateButton({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today, size: 14, color: Color(0xFF1A237E)),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Cards Row ────────────────────────────────────────────────────
class _SummaryCardsRow extends StatelessWidget {
  final SalesCollectionReportResponse report;
  final String Function(double) formatAmount;

  const _SummaryCardsRow({required this.report, required this.formatAmount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Net Total',
            amount: formatAmount(report.netTotal),
            icon: Icons.account_balance_wallet,
            color: Colors.blue,
            subtitle: 'Gross sales amount',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            label: 'Discount',
            amount: formatAmount(report.discount),
            icon: Icons.local_offer,
            color: Colors.orange,
            subtitle: 'Total discount given',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            label: 'VAT (13%)',
            amount: formatAmount(report.vat),
            icon: Icons.receipt,
            color: Colors.purple,
            subtitle: 'On net after discount',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            label: 'Grand Total',
            amount: formatAmount(report.total),
            icon: Icons.payments,
            color: Colors.green,
            subtitle: 'Net - Discount + VAT',
            isHighlighted: true,
          ),
        ),
      ],
    );
  }
}

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
                child: Icon(icon, color: isHighlighted ? Colors.white : color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : Colors.black87,
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

// ─── Payment Method Table ─────────────────────────────────────────────────
class _PaymentMethodTable extends StatelessWidget {
  final SalesCollectionReportResponse report;
  final String Function(double) formatAmount;
  final DateTime fromDate; // ← field
  final DateTime toDate;   // ← field

  const _PaymentMethodTable({
    required this.report,
    required this.formatAmount,
    required this.fromDate, // ← constructor
    required this.toDate,   // ← constructor
  });

  // ── Navigate to detail page — lives inside the class so it can access fromDate/toDate ──
  void _navigateToDetail(BuildContext context, String paymentMethod) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentDetailScreen(
          paymentMethod: paymentMethod, // ← e.g. "Cash", "Credit Card"
          fromDate: fromDate,           // ← class field
          toDate: toDate,               // ← class field
        ),
      ),
    );
  }

  List<_PaymentRow> get _rows {
    final ac = report.amountCalculation;
    return [
      _PaymentRow(label: 'Cash',        amount: ac.totalCash,       icon: Icons.money,           color: const Color(0xFF2E7D32)),
      _PaymentRow(label: 'Credit Card', amount: ac.totalCreditCard, icon: Icons.credit_card,     color: const Color(0xFF1565C0)),
      _PaymentRow(label: 'Online',      amount: ac.totalOnline,     icon: Icons.phone_android,   color: const Color(0xFF6A1B9A)),
      _PaymentRow(label: 'Credit',      amount: ac.totalCredit,     icon: Icons.account_balance, color: const Color(0xFFE65100)),
    ];
  }

  double get _grandTotal => _rows.fold(0, (sum, row) => sum + row.amount);

  @override
  Widget build(BuildContext context) {
    final rows = _rows;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.payment, color: Color(0xFF1A237E), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Payment Method Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rows.length} methods',
                    style: const TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Hint ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  'Tap a payment method to view its transactions',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),

          // ── Column headers ──
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text('#',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A237E),
                          fontSize: 13)),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Payment Method',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                          fontSize: 13)),
                ),
                Text('Amount',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                        fontSize: 13)),
                const SizedBox(width: 26),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Tappable rows ──
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;

            return Column(
              children: [
                InkWell(
                  onTap: () => _navigateToDetail(context, row.label), // ← row.label = "Cash" etc.
                  child: Container(
                    color: index.isEven ? Colors.white : Colors.grey.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        // # index
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Icon badge
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: row.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(row.icon, size: 16, color: row.color),
                        ),
                        const SizedBox(width: 10),

                        // Payment method name — bold, no underline
                        Expanded(
                          child: Text(
                            row.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: row.color,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        // Amount
                        Text(
                          formatAmount(row.amount),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        ),
                        const SizedBox(width: 8),

                        // Chevron
                        Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
              ],
            );
          }),

          // ── Footer total ──
          Container(
            color: const Color(0xFF1A237E).withOpacity(0.05),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const SizedBox(width: 32 + 8), // # + gap
                const Expanded(
                  child: Text(
                    'TOTAL COLLECTED',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                  ),
                ),
                Text(
                  formatAmount(_grandTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(width: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Internal data holder ─────────────────────────────────────────────────
class _PaymentRow {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _PaymentRow({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });
}

// ─── Error Banner ─────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onGenerate;
  const _EmptyState({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.insert_chart_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No report generated yet',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Select a date range and click "Generate Report"',
                style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}