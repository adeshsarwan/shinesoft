import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadedVideoStoreService {
  final Dio _dio = Dio();

  /// On Android 11+ (API 30+) use app-specific directory so no storage permission is needed.
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final android = await DeviceInfoPlugin().androidInfo;
      if (android.version.sdkInt >= 30) {
        final dir = await getTemporaryDirectory();
        return dir;
      }
    }

    // iOS does not support Android-style external storage paths.
    // Save into app Documents so it works and can be shown in iOS Files (if file sharing is enabled).
    final docsDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${docsDir.path}/Downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  // ============= DOWNLOAD VIDEO =============
  Future<String?> downloadVideoAsync(
    String url,
    String fileName, {
    Function(int received, int total)? onProgress,
  }) async {
    try {
      final directory = await _getDownloadDirectory();
      if (Platform.isAndroid) {
        final android = await DeviceInfoPlugin().androidInfo;
        if (android.version.sdkInt < 30) {
          await _askPermission();
          await Permission.storage.request();
        }
      }
      String savePath = "${directory.path}/$fileName.mp4";
      // Directory dir = await getApplicationDocumentsDirectory();
      // String savePath = "${dir.path}/$fileName.mp4";

      await _dio.download(
        url,
        savePath,
        options: Options(
          // responseType: ResponseType.bytes,
          // followRedirects: true,
          receiveTimeout: Duration(minutes: 5),
        ),
        onReceiveProgress: (count, total) {
          if (onProgress != null) {
            onProgress(count, total);
          }
          print("Video Download in progress...: ${(count / total * 100).toStringAsFixed(0)}%");
        },
      );
      print("savePath888888:- ${savePath}");
      return savePath;
    } catch (e) {
      print("Video Download Error: $e");
      return null;
    }
  }
  Future<String?> saveToDownload(String url, String fileName) async {
    try {
      final directory = await _getDownloadDirectory();
      if (Platform.isAndroid) {
        final android = await DeviceInfoPlugin().androidInfo;
        if (android.version.sdkInt < 30) {
          await Permission.storage.request();
        }
      }
      String savePath = "${directory.path}/$fileName.mp4";
      // Download file
      await Dio().download(url, savePath);
      print("Saved at: $savePath");
      return savePath;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }
  // ============= DOWNLOAD IMAGE (THUMBNAIL) =============
  Future<String?> downloadImage(String url, String fileName) async {
    try {
      await _askPermission();
      Directory dir = await getApplicationDocumentsDirectory();
      String savePath = "${dir.path}/$fileName.jpg";
      await _dio.download(
        url,
        savePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: Duration(seconds: 30),
        ),
      );

      return savePath;
    } catch (e) {
      print("Image Download Error: $e");
      return null;
    }
  }
  // ============= PERMISSION HANDLER =============
  Future<void> _askPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }
}
