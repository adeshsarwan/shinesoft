import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:iptv_demo/constant/app_urls.dart';

/// Shared HTTP client: default headers, timeouts, optional debug logging.
class ApiService extends GetxService {
  ApiService({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Headers sent on every request unless overridden.
  Map<String, String> get defaultHeaders => {
        'Accept': 'application/json',
        'Cookie': AppUrls.visitorCookie,
      };

  Map<String, String> _mergeHeaders(Map<String, String>? extra) {
    if (extra == null || extra.isEmpty) return Map<String, String>.from(defaultHeaders);
    return {...defaultHeaders, ...extra};
  }

  void _logRequest(
    String? tag,
    Uri uri,
    Map<String, String> headers, {
    Object? body,
  }) {
    if (!kDebugMode || tag == null) return;
    debugPrint('[$tag] Request URL: $uri');
    debugPrint('[$tag] Request Headers: ${jsonEncode(headers)}');
    if (body != null) {
      final raw = body is String ? body : jsonEncode(body);
      final preview = raw.length > 3000
          ? '${raw.substring(0, 3000)} ...[truncated]'
          : raw;
      debugPrint('[$tag] Request Body: $preview');
    }
  }

  void _logResponse(String? tag, http.Response response) {
    if (!kDebugMode || tag == null) return;
    debugPrint('[$tag] Status Code: ${response.statusCode}');
    debugPrint('[$tag] Response Headers: ${jsonEncode(response.headers)}');
    final body = response.body;
    final preview =
        body.length > 3000 ? '${body.substring(0, 3000)} ...[truncated]' : body;
    debugPrint('[$tag] Response Body: $preview');
    try {
      final decoded = json.decode(body);
      debugPrint('[$tag] Decoded Body Type: ${decoded.runtimeType}');
      if (decoded is Map<String, dynamic>) {
        debugPrint('[$tag] Top-level keys: ${decoded.keys.toList()}');
      }
    } catch (_) {
      debugPrint('[$tag] Response body is not valid JSON.');
    }
  }

  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
    String? debugTag,
  }) async {
    final merged = _mergeHeaders(headers);
    _logRequest(debugTag, uri, merged);
    final response = await _client
        .get(uri, headers: merged)
        .timeout(timeout ?? defaultTimeout);
    _logResponse(debugTag, response);
    return response;
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    String? debugTag,
  }) async {
    final merged = _mergeHeaders({
      'Content-Type': 'application/json',
      ...?headers,
    });
    _logRequest(debugTag, uri, merged, body: body);
    final response = await _client
        .post(uri, headers: merged, body: body)
        .timeout(timeout ?? defaultTimeout);
    _logResponse(debugTag, response);
    return response;
  }

  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    String? debugTag,
  }) async {
    final merged = _mergeHeaders({
      'Content-Type': 'application/json',
      ...?headers,
    });
    final encodedBody =
        body != null ? (body is String ? body : jsonEncode(body)) : null;
    _logRequest(debugTag, uri, merged, body: encodedBody);
    final request = http.Request('DELETE', uri);
    request.headers.addAll(merged);
    if (encodedBody != null) {
      request.body = encodedBody;
    }
    final streamed = await _client
        .send(request)
        .timeout(timeout ?? defaultTimeout);
    final response = await http.Response.fromStream(streamed);
    _logResponse(debugTag, response);
    return response;
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}
