import 'dart:convert';

import 'package:iptv_demo/model/country_item.dart';

/// Language rows for Settings. Can be static or API-backed.
class LanguageItem {
  const LanguageItem({required this.id, required this.label});
  final String id;
  final String label;
}

const List<LanguageItem> kStaticLanguages = [
  LanguageItem(id: 'All', label: 'All languages'),
  LanguageItem(id: 'Hindi', label: 'Hindi'),
  LanguageItem(id: 'English', label: 'English'),
];

/// Parses `GET /language` JSON.
/// Returns only active rows and prepends an "All languages" option.
List<LanguageItem> parseLanguagesFromApiBody(String body) {
  try {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      return <LanguageItem>[];
    }
    final data = decoded['data'];
    if (data is! List || data.isEmpty) {
      return <LanguageItem>[];
    }
    final out = <LanguageItem>[const LanguageItem(id: 'All', label: 'All languages')];
    for (final item in data) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final isActiveRaw = map['is_active'] ?? map['isActive'];
      final isActive = isActiveRaw == null ||
          isActiveRaw == true ||
          isActiveRaw == 1 ||
          isActiveRaw?.toString().toLowerCase() == 'true';
      if (!isActive) continue;
      final name = (map['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      out.add(LanguageItem(id: name, label: name));
    }
    return out.length > 1 ? out : <LanguageItem>[];
  } catch (_) {
    return <LanguageItem>[];
  }
}

/// Builds a mapping of UI label -> API code (`hin`, `eng`, ...).
/// Returns empty map if parsing fails.
Map<String, String> parseLanguageCodeMapFromApiBody(String body) {
  try {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      return <String, String>{};
    }
    final data = decoded['data'];
    if (data is! List || data.isEmpty) {
      return <String, String>{};
    }
    final out = <String, String>{};
    for (final item in data) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final name = (map['name'] ?? '').toString().trim();
      final code = (map['code'] ?? '').toString().trim().toLowerCase();
      if (name.isEmpty || code.isEmpty) continue;
      out[name] = code;
    }
    return out;
  } catch (_) {
    return <String, String>{};
  }
}

/// Display name for a country code.
/// NOTE: API-backed screens should render names directly from countries API rows.
String countryNameForCode(String code) {
  return code.toUpperCase();
}

/// Parses `GET /countries` JSON.
/// Returns an empty list when payload is invalid/unavailable.
List<CountryItem> parseCountriesFromApiBody(String body) {
  try {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      return <CountryItem>[];
    }
    final data = decoded['data'];
    if (data is! List || data.isEmpty) {
      return <CountryItem>[];
    }
    final out = <CountryItem>[];
    for (final item in data) {
      if (item is Map) {
        final c = CountryItem.fromJson(Map<String, dynamic>.from(item));
        if (c.code.isNotEmpty && c.name.isNotEmpty) {
          out.add(c);
        }
      }
    }
    return out;
  } catch (_) {
    return <CountryItem>[];
  }
}
