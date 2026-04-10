import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/config_service.dart';

class ApiClient {
  const ApiClient();

  static const _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await http
        .get(
          _buildUri(path, queryParameters: queryParameters),
          headers: _headers(),
        )
        .timeout(_timeout);

    _assertOk(response.statusCode);
    return _decodeMap(response.body);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http
        .post(
          _buildUri(path),
          headers: _headers(withJson: true),
          body: jsonEncode(body ?? const {}),
        )
        .timeout(_timeout);

    _assertOk(response.statusCode);
    return _decodeMap(response.body);
  }

  Future<int> postStatus(
    String path, {
    Map<String, dynamic>? body,
    required String baseUrl,
    required String apiKey,
  }) async {
    final response = await http
        .post(
          _buildUri(path, baseUrl: baseUrl),
          headers: _headers(withJson: true, apiKey: apiKey),
          body: jsonEncode(body ?? const {}),
        )
        .timeout(_timeout);

    return response.statusCode;
  }

  Future<List<dynamic>> postArray(
    String path, {
    List<Map<String, dynamic>>? body,
  }) async {
    final response = await http
        .post(
          _buildUri(path),
          headers: _headers(withJson: true),
          body: jsonEncode(body ?? const []),
        )
        .timeout(_timeout);

    _assertOk(response.statusCode);
    if (response.body.trim().isEmpty) return [];
    return await compute(jsonDecode, response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http
        .patch(
          _buildUri(path),
          headers: _headers(withJson: true),
          body: jsonEncode(body ?? const {}),
        )
        .timeout(_timeout);

    _assertOk(response.statusCode);
    return _decodeMap(response.body);
  }

  Future<void> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await http
        .delete(
          _buildUri(path, queryParameters: queryParameters),
          headers: _headers(),
        )
        .timeout(_timeout);

    _assertOk(response.statusCode);
  }

  void _assertOk(int statusCode) {
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('HTTP $statusCode');
    }
  }

  Uri _buildUri(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? baseUrl,
  }) {
    final cfg = ConfigService.instance;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final resolvedBaseUrl = (baseUrl ?? cfg.baseUrl).replaceAll(RegExp(r'/$'), '');
    final filteredQuery = queryParameters == null
        ? null
        : <String, String>{
            for (final entry in queryParameters.entries)
              if (entry.value != null) entry.key: '${entry.value}',
          };

    return Uri.parse('$resolvedBaseUrl/api/v1$normalizedPath').replace(
      queryParameters: filteredQuery?.isEmpty == true ? null : filteredQuery,
    );
  }

  Map<String, String> _headers({
    bool withJson = false,
    String? apiKey,
  }) {
    final cfg = ConfigService.instance;

    return {
      'X-N8N-API-KEY': apiKey ?? cfg.apiKey,
      if (withJson) 'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> _decodeMap(String body) async {
    if (body.trim().isEmpty) return <String, dynamic>{};
    return await compute(jsonDecode, body) as Map<String, dynamic>;
  }
}
