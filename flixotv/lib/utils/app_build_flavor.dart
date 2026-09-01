import 'package:package_info_plus/package_info_plus.dart';

/// Detects whether the installed APK is the `tv` or `mobile` product flavor.
class AppBuildFlavor {
  AppBuildFlavor._();

  static String? _versionName;

  static Future<String> versionName() async {
    _versionName ??= (await PackageInfo.fromPlatform()).version;
    return _versionName!;
  }

  /// Gradle adds `versionNameSuffix` (`-tv` / `-mobile`) to [versionName].
  static Future<bool> isTvApk() async {
    final v = await versionName();
    return v.contains('-tv');
  }

  static Future<bool> isMobileApk() async {
    final v = await versionName();
    return v.contains('-mobile');
  }
}
