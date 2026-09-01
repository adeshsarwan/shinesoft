import 'dart:convert';

/// Reads `userId` (or common aliases) from a JWT access token payload.
String? userIdFromAccessToken(String? token) {
  if (token == null || token.trim().isEmpty) return null;
  final parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    var payload = parts[1];
    final mod = payload.length % 4;
    if (mod > 0) payload += '=' * (4 - mod);
    final decoded = utf8.decode(base64Url.decode(payload));
    final map = jsonDecode(decoded);
    if (map is! Map<String, dynamic>) return null;
    for (final key in ['userId', 'user_id', 'userid', 'sub', 'id']) {
      final v = map[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
  } catch (_) {}
  return null;
}
