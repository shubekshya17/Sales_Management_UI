class UploadResult {
  final bool success;
  final String message;
  final int inserted;
  final int updated;
  final int failed;
  final int totalRowsInFile;
  final List<String> errors;

  const UploadResult({
    required this.success,
    required this.message,
    required this.inserted,
    required this.updated,
    required this.failed,
    required this.totalRowsInFile,
    required this.errors,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      // Safely parse bool — handles both true/false and missing key
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      inserted: json['inserted'] as int? ?? 0,
      updated: json['updated'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      totalRowsInFile: json['totalRowsInFile'] as int? ?? 0,
      // errors can be null or missing — default to empty list
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}