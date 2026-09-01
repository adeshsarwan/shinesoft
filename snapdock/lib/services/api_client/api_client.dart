import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  String _extractErrorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return "Failed: ${response.statusCode}";
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final dynamic message = decoded["message"] ?? decoded["error"] ?? decoded["detail"];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }
    } catch (_) {
      // Return fallback when response body is not JSON.
    }
    return "Failed: ${response.statusCode}";
  }

  Future<Map<String, dynamic>> getRequest(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final mergedHeaders = {
        if (headers != null) ...headers,
      };
      final response = await http.get(
        Uri.parse(url),
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
      );

      if (response.statusCode == 200) {
        return {
          "success": true,
          "data": jsonDecode(response.body),
        };
      } else {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": _extractErrorMessage(response),
          "rawBody": response.body,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error: $e",
      };
    }
  }

  Future<Map<String, dynamic>> postRequest(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final mergedHeaders = {
        "Content-Type": "application/json",
        if (headers != null) ...headers,
      };
      final response = await http.post(
        Uri.parse(url),
        headers: mergedHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "data": jsonDecode(response.body),
        };
      } else {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": _extractErrorMessage(response),
          "rawBody": response.body,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error: $e",
      };
    }
  }

  Future<Map<String, dynamic>> deleteRequest(String url, {Map<String, String>? headers}) async {
    try {
      final mergedHeaders = {
        "Content-Type": "application/json",
        if (headers != null) ...headers,
      };
      final response = await http.delete(
        Uri.parse(url),
        headers: mergedHeaders,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          "success": true,
          "data": response.body.isNotEmpty ? jsonDecode(response.body) : null,
        };
      } else {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": _extractErrorMessage(response),
          "rawBody": response.body,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error: $e",
      };
    }
  }

}
