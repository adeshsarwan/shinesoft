import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static SharedPreferences? _prefs;

  /// Initialize Prefs (Call this in main())
  static Future init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save any type of data
  static Future<bool> saveData(String key, dynamic value) async {
    if (value is String) {
      return await _prefs!.setString(key, value);
    } else if (value is int) {
      return await _prefs!.setInt(key, value);
    } else if (value is bool) {
      return await _prefs!.setBool(key, value);
    } else if (value is double) {
      return await _prefs!.setDouble(key, value);
    } else if (value is List<String>) {
      return await _prefs!.setStringList(key, value);
    } else {
      throw Exception("Invalid type");
    }
  }

  /// Get Data
  static dynamic getData(String key) {
    return _prefs!.get(key);
  }

  /// Remove one item
  static Future<bool> remove(String key) async {
    return await _prefs!.remove(key);
  }

  /// Clear all
  static Future<bool> clear() async {
    return await _prefs!.clear();
  }
}
