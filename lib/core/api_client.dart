import 'package:dio/dio.dart';
import 'package:sales_management_ui/models/category_dropdown.dart';
import 'package:sales_management_ui/models/product_dropdown.dart';
import 'package:sales_management_ui/models/product_ingredient_dropdown.dart';

const String baseUrl = 'http://localhost:5145/api';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  //Excel Upload
  static Future<Map<String, dynamic>> uploadCsv({
    required String endpoint,
    required String fileName,
    required List<int> fileBytes,
  }) async {
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

    final response = await _dio.post(
      endpoint,
      data: formData,
      options: Options(validateStatus: (status) => status! < 500),
    );

    return response.data as Map<String, dynamic>;
  }

  //List Category Range
  static Future<List<dynamic>> getCategoryRanges() async {
    final response = await _dio.get('/CategoryRange');
    return response.data as List<dynamic>;
  }

  //Create Category Range
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

  //SalesDetail Report
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

  //Sales Detail Report Category Wise
  static Future<List<dynamic>> getSalesByCategoryDetail({
    required DateTime fromDate,
    required DateTime toDate,
    required String categoryName,
  }) async {
    final response = await _dio.post(
      '/SalesDetailReport/category-detail',
      data: {
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
        'categoryName': categoryName,
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data as List<dynamic>;
  }

  //Sales Collection Report
  static Future<Map<String, dynamic>> getSalesCollectionReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final response = await _dio.post(
      '/SalesCollectionReport',
      data: {
        // Format: "2024-01-01T00:00:00" — what ASP.NET DateTime expects
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
  }

  //Sales Collection Detail Payment Method Wise
  static Future<List<dynamic>> getSalesDetailPaymentMethodWise({
    required DateTime fromDate,
    required DateTime toDate,
    required String paymentMethod,
  }) async {
    final response = await _dio.post(
      '/SalesCollectionReport/payment-detail',
      data: {
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
        'paymentMethod': paymentMethod,
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data as List<dynamic>;
  }

  static Future<List<dynamic>> getProductList() async {
    final response = await _dio.get('/Product');
    return response.data as List<dynamic>;
  }

  //Category Dropdown
  static Future<List<CategoryDropdown>> getCategoryDropdown() async {
    final response = await _dio.get('/CategoryRange/Dropdown');

    return (response.data as List)
        .map((item) => CategoryDropdown.fromJson(item))
        .toList();
  }

  //Product Dropdown By Category id
  static Future<List<ProductDropdown>> getProductDropdown(
    int categoryId,
  ) async {
    final response = await _dio.get(
      '/Product/Dropdown',
      queryParameters: {'categoryId': categoryId},
    );
    return (response.data as List)
        .map((item) => ProductDropdown.fromJson(item))
        .toList();
  }

  //Product Ingredient Dropdown
  static Future<List<ProductIngredientDropdown>>
  getProductIngredientDropdown() async {
    final response = await _dio.get('/ProductIngredient/Dropdown');
    return (response.data as List)
        .map((item) => ProductIngredientDropdown.fromJson(item))
        .toList();
  }
}
