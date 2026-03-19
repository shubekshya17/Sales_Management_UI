import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/api_client.dart';
import '../models/upload_result.dart';

class CsvUploadCard extends StatefulWidget {
  final String title;       // e.g. "Sales Collection"
  final String apiEndpoint; // e.g. "/salescollection/upload"

  const CsvUploadCard({
    super.key,
    required this.title,
    required this.apiEndpoint,
  });

  @override
  State<CsvUploadCard> createState() => _CsvUploadCardState();
}

class _CsvUploadCardState extends State<CsvUploadCard> {
  bool _isLoading = false;       // Shows spinner while uploading
  UploadResult? _lastResult;     // Stores the API response
  String? _errorMessage;         // Stores any error message

  Future<void> _pickAndUpload() async {
    // Open file picker — only allows .csv files
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true, // IMPORTANT for Flutter Web: loads bytes into memory
    );

    // User pressed Cancel
    if (pickerResult == null || pickerResult.files.isEmpty) return;

    final file = pickerResult.files.first;

    if (file.bytes == null) {
      setState(() => _errorMessage = 'Could not read file. Please try again.');
      return;
    }

    // Show spinner
    setState(() {
      _isLoading = true;
      _lastResult = null;
      _errorMessage = null;
    });

    try {
      // Call your API
      final responseJson = await ApiClient.uploadCsv(
        endpoint: widget.apiEndpoint,
        fileName: file.name,
        fileBytes: file.bytes!,
      );

      // Convert JSON response to UploadResult object
      setState(() {
        _lastResult = UploadResult.fromJson(responseJson);
      });
    } catch (e) {
      setState(() => _errorMessage = 'Upload failed: $e');
    } finally {
      // Always hide spinner when done
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card title
            Row(
              children: [
                const Icon(Icons.upload_file, color: Color(0xFF1A237E)),
                const SizedBox(width: 8),
                Text(
                  'Upload ${widget.title} Excel File',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a .xlsx file from your computer to import data.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Upload button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoading ? null : _pickAndUpload,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload),
              label: Text(_isLoading ? 'Uploading...' : 'Choose & Upload CSV'),
            ),

            // Result section — only shown after upload
            if (_lastResult != null) ...[
              const SizedBox(height: 20),
              _ResultBanner(result: _lastResult!),
            ],

            // Error section
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
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Shows the green/red result banner after upload
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
          // Success/fail message
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

          // Stats chips: Inserted / Skipped / Failed / Total
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

          // Error list if any rows failed
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Row Errors:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            color: color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}