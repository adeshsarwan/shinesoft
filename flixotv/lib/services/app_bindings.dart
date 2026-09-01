import 'package:get/get.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/repositories/auth_repository.dart';
import 'package:iptv_demo/repositories/iptv_repository.dart';
import 'package:iptv_demo/repositories/notification_repository.dart';
import 'package:iptv_demo/repositories/stripe_repository.dart';
import 'package:iptv_demo/services/api_service.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/services/schedule_reminder_service.dart';
import 'package:iptv_demo/services/notification_service.dart';
import 'package:iptv_demo/services/stripe_payment_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    final api = Get.put(ApiService(), permanent: true);
    Get.put(StripeRepository(api), permanent: true);
    Get.put(StripePaymentService(), permanent: true);
    Get.put(AuthRepository(api), permanent: true);
    Get.put(NotificationRepository(api), permanent: true);
    Get.put(IptvRepository(api), permanent: true);
    Get.put(NotificationService(), permanent: true);
    Get.putAsync<AuthService>(() async => AuthService(), permanent: true);
    Get.putAsync<ScheduleReminderService>(
      ScheduleReminderService.create,
      permanent: true,
    );
    Get.put(IptvController(), permanent: true);
  }
}