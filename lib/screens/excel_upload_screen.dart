import 'dart:typed_data';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/api_client.dart';
import '../models/upload_result.dart';

// ─── Top-level header parser ───────────────────────────────────────────────
// Scans rows to find the REAL header row, skipping metadata rows at the top.
// Works even when the file has "From Date:", "To Date:" rows before headers.
List<String> _extractHeaders(Uint8List bytes) {
  try {
    final workbook = xl.Excel.decodeBytes(bytes);
    final sheet = workbook.sheets.values.first;
    if (sheet.rows.isEmpty) return [];

    for (final row in sheet.rows) {
      // Get all non-empty cell values in this row
      final cells = row
          .map((cell) => cell?.value?.toString().trim() ?? '')
          .where((h) => h.isNotEmpty)
          .toList();

      // Skip rows with fewer than 3 cells (blank rows or sparse metadata)
      if (cells.length < 3) continue;

      // Skip rows that look like metadata lines e.g.
      // "From Date : 15/Jan/2026 (01/10/2082)"
      // "To Date : 14/Mar/2026 (30/11/2082)"
      final first = cells.first.toLowerCase();
      if (first.startsWith('from') ||
          first.startsWith('to') ||
          first.startsWith('date') ||
          RegExp(r'^\d{2}/\d{2}/\d{4}').hasMatch(cells.first)) {
        continue;
      }

      // This is the header row
      return cells;
    }

    return [];
  } catch (_) {
    return [];
  }
}

// ─── Upload Type Definition ────────────────────────────────────────────────
class _UploadType {
  final String label;
  final String endpoint;
  final String description;
  final IconData icon;
  final List<String> expectedHeaders;

  const _UploadType({
    required this.label,
    required this.endpoint,
    required this.description,
    required this.icon,
    required this.expectedHeaders,
  });
}

const List<_UploadType> _uploadTypes = [
  _UploadType(
    label: 'Sales Collection',
    endpoint: '/SalesCollection/upload',
    description: 'Upload sales collection records from Excel',
    icon: Icons.receipt_long,
    expectedHeaders: [
      'Date',
      'Invoice',
      'Party',
      'Gross',
      'Discount',
      'NetSale',
      'Vat',
      'Total',
      'TRNUser',
      'TRNTime',
      'STax',
      'Pax',
      'BillToPan',
      'BillToMob',
      'Cash',
      'CreditCard',
      'Credit',
      'Online',
      'GVoucher',
      'SalesReturnVoucher',
      'Complimentary',
      'TransactionId',
      'OrderMode',
    ],
  ),
  _UploadType(
    label: 'Sales Detail',
    endpoint: '/SalesDetail/upload',
    description: 'Upload detailed sales line items from Excel',
    icon: Icons.list_alt,
    expectedHeaders: [
      'TRNDATE',
      'BSDate',
      'VCHRNO',
      'REFNO',
      'ItemCode',
      'Desca',
      'BillTo',
      'Barcode',
      'BillUnit',
      'BillQty',
      'BillRate',
      'BaseUnit',
      'BaseQty',
      'BaseRate',
      'Amount',
      'Discount',
      'SCharge',
      'NetSale',
      'Taxable',
      'NonTaxable',
      'Vat',
      'NetAmnt',
      'TRNUser',
      'TRNTime',
      'Division',
      'Salesman',
      'MobileNo',
      'StartTime',
      'EndTime',
      'Terminal',
    ],
  ),
  _UploadType(
    label: 'KOT',
    endpoint: '/kot/upload',
    description: 'Upload Kitchen Order Tickets from Excel',
    icon: Icons.restaurant_menu,
    expectedHeaders: ['TRNDATE', 'KOTNO'],
  ),
];

// ─── Screen ────────────────────────────────────────────────────────────────
class ExcelUploadScreen extends StatefulWidget {
  const ExcelUploadScreen({super.key});

  @override
  State<ExcelUploadScreen> createState() => _ExcelUploadScreenState();
}

class _ExcelUploadScreenState extends State<ExcelUploadScreen> {
  _UploadType _selected = _uploadTypes.first;

  bool _isValidating = false;
  bool _isUploading = false;
  UploadResult? _lastResult;
  String? _errorMessage;
  String? _selectedFileName;

  bool get _isBusy => _isValidating || _isUploading;

  // ── Dropdown change ───────────────────────────────────────────────────────
  void _onTypeChanged(_UploadType newType) {
    setState(() {
      _selected = newType;
      _lastResult = null;
      _errorMessage = null;
      _selectedFileName = null;
    });
  }

  // ── Validate headers ──────────────────────────────────────────────────────
  // NOTE: On Flutter Web, excel decoding blocks the JS thread and freezes the
  // browser. We skip client-side validation on web and let the backend handle it.
  Future<String?> _validateHeaders(Uint8List fileBytes) async {
    if (kIsWeb) {
      // Skip validation on web — backend will reject wrong files
      return null;
    }

    // Yield one frame so spinner renders before heavy parsing begins
    await Future.delayed(Duration.zero);

    final actualHeaders = _extractHeaders(fileBytes);

    if (actualHeaders.isEmpty) {
      return 'Could not find a header row in this file.\n'
          'Make sure the file has column headers.';
    }

    // Case-insensitive so ITEMCODE matches ItemCode, DESCA matches Desca etc.
    final actualLower = actualHeaders.map((h) => h.toLowerCase()).toSet();
    final missing = _selected.expectedHeaders
        .where((col) => !actualLower.contains(col.toLowerCase()))
        .toList();

    if (missing.isNotEmpty) {
      return 'Wrong file for "${_selected.label}".\n'
          'Missing columns:\n• ${missing.join('\n• ')}';
    }

    return null; 
  }

  // ── Pick → Validate → Upload ──────────────────────────────────────────────
  Future<void> _pickAndUpload() async {
    // 1. Open file picker
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (pickerResult == null || pickerResult.files.isEmpty) return;

    final file = pickerResult.files.first;

    if (file.bytes == null) {
      setState(
        () => _errorMessage = 'Could not read file bytes. Please try again.',
      );
      return;
    }

    // 2. Show validating state
    setState(() {
      _isValidating = true;
      _isUploading = false;
      _lastResult = null;
      _errorMessage = null;
      _selectedFileName = file.name;
    });

    // 3. Validate headers
    final validationError = await _validateHeaders(file.bytes!);

    if (validationError != null) {
      setState(() {
        _isValidating = false;
        _errorMessage = validationError;
      });
      return; 
    }

    // 4. Headers OK — upload
    setState(() {
      _isValidating = false;
      _isUploading = true;
    });

    try {
      final responseJson = await ApiClient.uploadCsv(
        endpoint: _selected.endpoint,
        fileName: file.name,
        fileBytes: file.bytes!,
      );
      final result = UploadResult.fromJson(responseJson);
      setState(() {
        // If backend says success=false, show as error message not result banner
        if (!result.success &&
            result.inserted == 0 &&
            result.message.isNotEmpty) {
          _errorMessage =
              result.message; // ← shows "Wrong file type. Missing columns..."
        } else {
          _lastResult = result; // ← shows the stats banner for real uploads
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Upload failed: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ── Button label ──────────────────────────────────────────────────────────
  String get _buttonLabel {
    if (_isValidating) return 'Validating...';
    if (_isUploading) return 'Uploading...';
    return 'Upload ${_selected.label}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
                  'Excel Upload',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Select a file type and upload your Excel data',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // ── Main Card ──
          Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Step 1 ──
                    const _StepLabel(number: '1', text: 'Select File Type'),
                    const SizedBox(height: 8),

                    // Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<_UploadType>(
                          value: _selected,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF1A237E),
                          ),
                          items: _uploadTypes.map((type) {
                            return DropdownMenuItem<_UploadType>(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    type.icon,
                                    size: 18,
                                    color: const Color(0xFF1A237E),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    type.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _isBusy
                              ? null
                              : (value) {
                                  if (value != null) _onTypeChanged(value);
                                },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selected.description,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 20),

                    // ── Step 2 ──
                    const _StepLabel(number: '2', text: 'Upload Excel File'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Upload button
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
                          onPressed: _isBusy ? null : _pickAndUpload,
                          icon: _isBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upload),
                          label: Text(_buttonLabel),
                        ),

                        const SizedBox(width: 16),

                        // Filename chip — red if error, green if ok
                        if (_selectedFileName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _errorMessage != null
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _errorMessage != null
                                    ? Colors.red.shade200
                                    : Colors.green.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.description,
                                  size: 16,
                                  color: _errorMessage != null
                                      ? Colors.red.shade600
                                      : Colors.green.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedFileName!,
                                  style: TextStyle(
                                    color: _errorMessage != null
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Accepted formats: .xlsx, .xls',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),

                    // ── Validating indicator ──
                    if (_isValidating) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Checking file headers...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ── Success result ──
                    if (_lastResult != null) ...[
                      const SizedBox(height: 24),
                      _ResultBanner(result: _lastResult!),
                    ],

                    // ── Error banner ──
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Label ────────────────────────────────────────────────────────────
class _StepLabel extends StatelessWidget {
  final String number;
  final String text;
  const _StepLabel({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF1A237E),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ],
    );
  }
}

// ─── Result Banner ─────────────────────────────────────────────────────────
class _ResultBanner extends StatelessWidget {
  final UploadResult result;
  const _ResultBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.success ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.success ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.cancel,
                color: result.success ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: result.success
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip('Inserted', result.inserted, Colors.green),
              _StatChip('Updated', result.updated, Colors.orange),
              _StatChip('Failed', result.failed, Colors.red),
              _StatChip('Total Rows', result.totalRowsInFile, Colors.blue),
            ],
          ),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Row Errors:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            ...result.errors.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $e',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Stat Chip ─────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
