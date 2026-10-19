import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/cursor_pagination.dart';
import '../../../core/api/page_pagination.dart';
import '../domain/fee_model.dart';
import '../domain/invoice_file.dart';
import 'fee_api.dart';

class FeeRepository {
  final FeeApi _api;

  FeeRepository(this._api);

  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) async {
    try {
      final response = await _api.getFees(
        studentId: studentId,
        search: search,
        cursor: cursor,
      );
      final data = response.data;
      final items = (data['data'] as List)
          .map((e) => FeeModel.fromJson(e))
          .toList();
      final meta = data['meta'] ?? {};
      return CursorPagination(
        data: items,
        nextCursor: meta['cursor'],
        hasMore: meta['has_more'] ?? false,
        total: meta['total'],
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FeeModel> getFee(String id) async {
    try {
      final response = await _api.getFee(id);
      return FeeModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<PageResult<FeeModel>> getStudentFees(
    String studentAppId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.getFees(
        studentAppId: studentAppId,
        page: page,
        limit: limit,
      );
      return PageResult.fromJson(
        response.data,
        page: page,
        perPage: limit,
        parse: FeeModel.fromJson,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> uploadProof(
    String feeId, {
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      await _api.uploadProof(feeId, bytes: bytes, filename: filename);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> getInvoiceUrl(String feeId) async {
    try {
      final response = await _api.getInvoiceLink(feeId);
      return response.data['data']['url']?.toString() ?? '';
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Link firmado + bytes del PDF de la factura, para el visor in-app.
  Future<InvoiceFile> getInvoiceFile(String feeId) async {
    final url = await getInvoiceUrl(feeId);

    if (url.isEmpty) {
      throw ApiException(
        message: 'Factura no disponible',
        statusCode: 404,
      );
    }

    try {
      final response = await _api.getInvoiceBytes(url);
      final bytes = Uint8List.fromList(response.data ?? const []);

      if (bytes.isEmpty) {
        throw ApiException(message: 'Factura vacía');
      }

      return InvoiceFile(bytes: bytes, url: url);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error inesperado',
      statusCode: e.response?.statusCode,
    );
  }
}
