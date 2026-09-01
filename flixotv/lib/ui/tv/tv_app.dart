import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/app_theme.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/routes/app_pages.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/app_bindings.dart';

class TvApp extends StatefulWidget {
  const TvApp({super.key});

  @override
  State<TvApp> createState() => _TvAppState();
}

class _TvAppState extends State<TvApp> {
  @override
  void initState() {
    super.initState();
    // Android TV remotes sometimes fire a KeyUpEvent for the Back/GoBack key
    // without a preceding KeyDownEvent. Flutter's HardwareKeyboard asserts
    // that every KeyUp must have a matching KeyDown, which throws an assertion
    // error. We suppress it by pre-registering the key as "pressed" whenever
    // we see an orphaned KeyUp for the Go Back physical key.
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    // If a KeyUpEvent arrives for a key that isn't tracked as pressed,
    // synthesise a KeyDownEvent first so Flutter's state stays consistent.
    if (event is KeyUpEvent) {
      final isTracked = HardwareKeyboard.instance.physicalKeysPressed
          .contains(event.physicalKey);
      if (!isTracked) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: '${AppStrings.appTitle} TV',
          theme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          initialRoute: AppRoutes.SPLASH,
          getPages: AppPages.pages,
          initialBinding: AppBindings(),
        );
      },
    );
  }
}
