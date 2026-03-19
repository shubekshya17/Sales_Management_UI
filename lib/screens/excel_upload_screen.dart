import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/api_client.dart';
import '../models/upload_result.dart';

// Defines all uploadable file types in one place
// To add a new type later, just add an entry here — nothing else changes
class _UploadType {
  final String label;       // Shown in dropdown
  final String endpoint;    // API endpoint to call
  final String description; // Subtitle shown on screen
  final IconData icon;

  const _UploadType({
    required this.label,
    required this.endpoint,
    required this.description,
    required this.icon,
  });
}

const List<_UploadType> _uploadTypes = [
  _UploadType(
    label: 'Sales Collection',
    endpoint: '/SalesCollection/upload',
    description: 'Upload sales collection records from Excel',
    icon: Icons.receipt_long,
  ),
  _UploadType(
    label: 'Sales Detail',
    endpoint: '/SalesDetail/upload',
    description: 'Upload detailed sales line items from Excel',
    icon: Icons.list_alt,
  ),
  _UploadType(
    label: 'KOT',
    endpoint: '/kot/upload',
    description: 'Upload Kitchen Order Tickets from Excel',
    icon: Icons.restaurant_menu,
  ),
];

class ExcelUploadScreen extends StatefulWidget {
  const ExcelUploadScreen({super.key});

  @override
  State<ExcelUploadScreen> createState() => _ExcelUploadScreenState();
}

class _ExcelUploadScreenState extends State<ExcelUploadScreen> {
  // Currently selected upload type — defaults to first item
  _UploadType _selected = _uploadTypes.first;

  bool _isLoading = false;
  UploadResult? _lastResult;
  String? _errorMessage;
  String? _selectedFileName; // Shows which file was picked

  // ── Reset result when dropdown changes ────────────────────────────────────
  void _onTypeChanged(_UploadType newType) {
    setState(() {
      _selected = newType;
      _lastResult = null;       // Clear old result
      _errorMessage = null;
      _selectedFileName = null; // Clear old filename
    });
  }

  // ── Pick file and upload ───────────────────────────────────────────────────
  Future<void> _pickAndUpload() async {
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (pickerResult == null || pickerResult.files.isEmpty) return;

    final file = pickerResult.files.first;

    if (file.bytes == null) {
      setState(() => _errorMessage = 'Could not read file. Please try again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResult = null;
      _errorMessage = null;
      _selectedFileName = file.name;
    });

    try {
      final responseJson = await ApiClient.uploadCsv(
        endpoint: _selected.endpoint,
        fileName: file.name,
        fileBytes: file.bytes!,
      );

      setState(() {
        _lastResult = UploadResult.fromJson(responseJson);
      });
    } catch (e) {
      setState(() => _errorMessage = 'Upload failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Excel Upload',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Select a file type and upload your Excel data',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // ── Main Upload Card ──
          Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Step 1: Choose type ──
                    const _StepLabel(number: '1', text: 'Select File Type'),
                    const SizedBox(height: 12),

                    // Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<_UploadType>(
                          value: _selected,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Color(0xFF1A237E)),
                          items: _uploadTypes.map((type) {
                            return DropdownMenuItem<_UploadType>(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(type.icon,
                                      size: 18,
                                      color: const Color(0xFF1A237E)),
                                  const SizedBox(width: 10),
                                  Text(
                                    type.label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) _onTypeChanged(value);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Dynamic description under dropdown
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          _selected.description,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 20),

                    // ── Step 2: Upload file ──
                    const _StepLabel(number: '2', text: 'Upload Excel File'),
                    const SizedBox(height: 12),

                    // File info + Upload button row
                    Row(
                      children: [
                        // Upload button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isLoading ? null : _pickAndUpload,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.upload),
                          // Button label changes based on selection
                          label: Text(
                            _isLoading
                                ? 'Uploading...'
                                : 'Upload ${_selected.label}',
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Selected filename chip — shown after file picked
                        if (_selectedFileName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.description,
                                    size: 16,
                                    color: Colors.green.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedFileName!,
                                  style: TextStyle(
                                    color: Colors.green.shade700,
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
                          fontSize: 12, color: Colors.grey.shade400),
                    ),

                    // ── Result banner ──
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
                          border:
                              Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.red)),
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

// ─── Step Label Widget ─────────────────────────────────────────────────────
// The little "① Select File Type" label above each step
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
                fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 15),
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
          color: result.success
              ? Colors.green.shade300
              : Colors.red.shade300,
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
              Text(
                result.message,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: result.success
                      ? Colors.green.shade800
                      : Colors.red.shade800,
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
              _StatChip('Skipped', result.skipped, Colors.orange),
              _StatChip('Failed', result.failed, Colors.red),
              _StatChip('Total Rows', result.totalRowsInFile, Colors.blue),
            ],
          ),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Row Errors:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            ...result.errors.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $e',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.red)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
            fontSize: 13),
      ),
    );
  }
}
