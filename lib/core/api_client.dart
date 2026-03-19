import 'package:dio/dio.dart';

const String baseUrl = 'http://localhost:5145/api';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // Uploads a CSV file to your API
  // endpoint = '/salescollection/upload' or '/salesdetail/upload'
  static Future<Map<String, dynamic>> uploadCsv({
    required String endpoint,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    // This creates the multipart/form-data body your API expects
    // Your API has [FromForm] FileUploadDto with a "File" property
    // so the field name here must be "file" (case-insensitive on ASP.NET)
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: DioMediaType(
          'application',
          'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ),
    });

    final response = await _dio.post(endpoint, data: formData);
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getCategoryRanges() async {
    final response = await _dio.get('/CategoryRange');
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createCategoryRange(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(
      '/CategoryRange',
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/salesdetailreport
  /// Your API takes { fromDate, toDate } and returns the full report
  static Future<Map<String, dynamic>> getSalesDetailReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final response = await _dio.post(
      '/SalesDetailReport',
      data: {
        // Format: "2024-01-01T00:00:00" — what ASP.NET DateTime expects
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
  }
}
