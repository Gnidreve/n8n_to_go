import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/config_service.dart';

class ApiClient {
  const ApiClient();

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await http.get(
      _buildUri(path, queryParameters: queryParameters),
      headers: _headers(),
    );

    return _decodeMap(response.body);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      _buildUri(path),
      headers: _headers(withJson: true),
      body: jsonEncode(body ?? const {}),
    );

    return _decodeMap(response.body);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.patch(
      _buildUri(path),
      headers: _headers(withJson: true),
      body: jsonEncode(body ?? const {}),
    );

    return _decodeMap(response.body);
  }

  Future<void> delete(String path) async {
    await http.delete(
      _buildUri(path),
      headers: _headers(),
    );
  }

  Uri _buildUri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final cfg = ConfigService.instance;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final filteredQuery = queryParameters == null
        ? null
        : <String, String>{
            for (final entry in queryParameters.entries)
              if (entry.value != null) entry.key: '${entry.value}',
          };

    return Uri.parse('${cfg.baseUrl}/api/v1$normalizedPath').replace(
      queryParameters: filteredQuery?.isEmpty == true ? null : filteredQuery,
    );
  }

  Map<String, String> _headers({bool withJson = false}) {
    final cfg = ConfigService.instance;

    return {
      'X-N8N-API-KEY': cfg.apiKey,
      if (withJson) 'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> _decodeMap(String body) async {
    if (body.trim().isEmpty) return <String, dynamic>{};
    return await compute(jsonDecode, body) as Map<String, dynamic>;
  }
}
