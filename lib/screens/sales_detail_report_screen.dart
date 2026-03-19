import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/sales_detail_report.dart';

class SalesDetailReportScreen extends StatefulWidget {
  const SalesDetailReportScreen({super.key});

  @override
  State<SalesDetailReportScreen> createState() =>
      _SalesDetailReportScreenState();
}

class _SalesDetailReportScreenState extends State<SalesDetailReportScreen> {
  // Date range — defaults to current month
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();

  SalesDetailReportResponse? _report;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Fetch report from API
  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final json = await ApiClient.getSalesDetailReport(
        fromDate: _fromDate,
        toDate: _toDate,
      );
      setState(() {
        _report = SalesDetailReportResponse.fromJson(json);
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to generate report: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Date picker helper ─────────────────────────────────────────────────────
  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        // Match app color theme
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
        // Auto-correct: if fromDate is after toDate, move toDate forward
        if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
      } else {
        _toDate = picked;
      }
    });
  }

  // ── Format helpers ─────────────────────────────────────────────────────────
  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatAmount(double amount) {
    // Formats 84750.0 → "84,750.00"
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

  // ── Build ──────────────────────────────────────────────────────────────────
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
                'Sales Detail Report',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Category-wise sales breakdown with VAT calculation',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),

        // ── Scrollable Content ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date Filter Card ──
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

                // ── Error ──
                if (_errorMessage != null)
                  _ErrorBanner(message: _errorMessage!),

                // ── Loading ──
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ),

                // ── Report Results ──
                if (_report != null && !_isLoading) ...[
                  // Summary cards row
                  _SummaryCardsRow(
                    report: _report!,
                    formatAmount: _formatAmount,
                  ),

                  const SizedBox(height: 24),

                  // Category breakdown table
                  _CategoryTable(report: _report!, formatAmount: _formatAmount),
                ],

                // ── Empty state (before first generate) ──
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
            const Text(
              'Date Range:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 16),

            // From Date button
            _DateButton(
              label: 'From',
              date: formatDate(fromDate),
              onTap: onFromTap,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
            ),

            // To Date button
            _DateButton(label: 'To', date: formatDate(toDate), onTap: onToTap),

            const Spacer(),

            // Generate Report button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isLoading ? null : onGenerate,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
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

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

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
            Text(
              '$label: ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            Text(
              date,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.calendar_today,
              size: 14,
              color: Color(0xFF1A237E),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Cards Row ────────────────────────────────────────────────────
class _SummaryCardsRow extends StatelessWidget {
  final SalesDetailReportResponse report;
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
            isHighlighted: true, // Makes grand total stand out
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
        // Highlighted card (Grand Total) gets a solid dark background
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
          // Icon + Label row
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

          // Amount
          Text(
            amount,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
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

// ─── Category Table ───────────────────────────────────────────────────────
class _CategoryTable extends StatelessWidget {
  final SalesDetailReportResponse report;
  final String Function(double) formatAmount;

  const _CategoryTable({required this.report, required this.formatAmount});

  @override
  Widget build(BuildContext context) {
    final categories = report.categoryWiseAmount;
    final totalAmount = report.netTotal;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.pie_chart_outline,
                  color: Color(0xFF1A237E),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Category-wise Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${categories.length} categor${categories.length == 1 ? 'y' : 'ies'}',
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

          // Table
          SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columnSpacing: 40,
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
                fontSize: 13,
              ),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Category Name')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('% of Total')),
                DataColumn(label: Text('Share Bar')),
              ],
              rows: categories.asMap().entries.map((entry) {
                final index = entry.key;
                final cat = entry.value;

                // Calculate percentage of total
                final pct = totalAmount > 0
                    ? (cat.amount / totalAmount * 100)
                    : 0.0;

                return DataRow(
                  color: WidgetStateProperty.all(
                    index.isEven ? Colors.white : Colors.grey.shade50,
                  ),
                  cells: [
                    // Row number
                    DataCell(
                      Text(
                        '${index + 1}',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),

                    // Category name with color dot
                    DataCell(
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _categoryColor(index),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat.categoryName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    // Amount
                    DataCell(
                      Text(
                        formatAmount(cat.amount),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),

                    // Percentage badge
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _categoryColor(index).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _categoryColor(index),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    // Visual share bar
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _categoryColor(index),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // ── Table Footer — Totals row ──
          const Divider(height: 1),
          Container(
            color: const Color(0xFF1A237E).withOpacity(0.05),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const SizedBox(width: 40), // # column
                const Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
                Text(
                  formatAmount(report.netTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(int index) {
    const colors = [
      Color(0xFF1565C0), // blue
      Color(0xFF2E7D32), // green
      Color(0xFFE65100), // orange
      Color(0xFF6A1B9A), // purple
      Color(0xFFC62828), // red
      Color(0xFF00695C), // teal
      Color(0xFF4527A0), // deep purple
      Color(0xFF558B2F), // light green
    ];
    return colors[index % colors.length];
  }
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
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State (before first generate) ────────────────────────────────
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
            Icon(
              Icons.insert_chart_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No report generated yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a date range and click "Generate Report"',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              onPressed: onGenerate,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Generate Now'),
            ),
          ],
        ),
      ),
    );
  }
}
