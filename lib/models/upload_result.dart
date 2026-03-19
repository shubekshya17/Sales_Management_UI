class UploadResult {
  final bool success;
  final String message;
  final int inserted;
  final int skipped;
  final int failed;
  final int totalRowsInFile;
  final List<String> errors;

  UploadResult({
    required this.success,
    required this.message,
    required this.inserted,
    required this.skipped,
    required this.failed,
    required this.totalRowsInFile,
    required this.errors,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      inserted: json['inserted'] ?? 0,
      skipped: json['skipped'] ?? 0,
      failed: json['failed'] ?? 0,
      totalRowsInFile: json['totalRowsInFile'] ?? 0,
      errors: List<String>.from(json['errors'] ?? []),
    );
  }
}