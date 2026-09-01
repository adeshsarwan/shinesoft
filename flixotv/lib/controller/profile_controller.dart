import 'package:get/get.dart';
import 'package:iptv_demo/model/user_profile.dart';
import 'package:iptv_demo/services/auth_service.dart';

class ProfileController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final profile = Rxn<UserProfile>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = '';
    final (p, msg) = await _auth.fetchProfile();
    profile.value = p;
    if (p == null) {
      errorMessage.value = msg.isNotEmpty ? msg : 'Could not load profile';
    }
    isLoading.value = false;
  }
}
