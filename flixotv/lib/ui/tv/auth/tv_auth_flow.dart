import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/routes/app_routes.dart';

/// Opens the TV login screen (full route, not a dialog).
Future<void>? openTvLoginScreen({VoidCallback? onSessionEstablished}) {
  return Get.toNamed<void>(
    AppRoutes.LOGIN_TV,
    arguments: onSessionEstablished,
  );
}
