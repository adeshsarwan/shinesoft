import 'package:flutter/material.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/state/premium_state.dart';
import 'package:videodownloader/core/storage/shared_preferences/shared_prefs.dart';
import 'package:videodownloader/core/theme/color_utility.dart';
import 'package:videodownloader/l10n/app_localizations.dart';
import 'package:videodownloader/screens/auth/login_screen.dart';
import 'package:videodownloader/screens/language/language_selection_screen.dart';
import 'package:videodownloader/screens/profile/about_app_screen/about_app_screen.dart';
import 'package:videodownloader/screens/profile/contact_us_screen/contact_us_screen.dart';
import 'package:videodownloader/screens/profile/privacy_policy_screen/privacy_policy_screen.dart';
import 'package:videodownloader/screens/profile/subscription_screen/subscription_screen.dart';
import 'package:videodownloader/services/api_client/api_client.dart';
import 'package:videodownloader/services/auth_services/delete_account_service/delete_account_service.dart';
import 'package:videodownloader/services/auth_services/logout_service/logout_service.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "";
  String _userEmail = "";
  bool _isGuestUser = false;
  // Tracks whether an auth-related API call is in progress.
  bool _isProcessing = false;

  late final LogoutService _logoutService;
  late final DeleteAccountService _deleteAccountService;

  // Treat user as "guest" only if explicitly flagged as guest
  // or if we don't even have an email saved yet.
  bool get _showGuestState => _isGuestUser || _userEmail.isEmpty;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _logoutService = LogoutService(apiClient: apiClient);
    _deleteAccountService = DeleteAccountService(apiClient: apiClient);
    getSelectedLanguage();
  }

  void getSelectedLanguage() {
    final savedIsGuest = SharedPrefs.getData(PrefsConstants.isGuestUser);
    final savedUserName = SharedPrefs.getData(PrefsConstants.userName);
    final savedUserEmail = SharedPrefs.getData(PrefsConstants.userEmail);
    final userName = savedUserName is String ? savedUserName.trim() : '';
    final userEmail = savedUserEmail is String ? savedUserEmail.trim() : '';
    final isGuest = savedIsGuest is bool && savedIsGuest == true;
    // Consider the user "non-guest" as soon as we have an email stored.
    final hasSavedData = userEmail.isNotEmpty;

    setState(() {
      _isGuestUser = isGuest || !hasSavedData;
      _userName = userName;
      _userEmail = userEmail;
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      // Global locale is managed in appLocaleNotifier; this triggers redraw.
    });
  }

  void _setGuestSessionWithoutNavigation() {
    SharedPrefs.saveData(PrefsConstants.isLoggedIn, false);
    SharedPrefs.saveData(PrefsConstants.isGuestUser, true);
    SharedPrefs.saveData(PrefsConstants.isPremiumUser, false);
    SharedPrefs.saveData(PrefsConstants.userName, "");
    SharedPrefs.saveData(PrefsConstants.userEmail, "");
    SharedPrefs.saveData(PrefsConstants.userToken, "");
    SharedPrefs.remove(PrefsConstants.accessToken);
    SharedPrefs.remove(PrefsConstants.refreshToken);
    PremiumState.isPremium.value = false;
    setState(() {
      _isGuestUser = true;
      _userName = "";
      _userEmail = "";
    });
  }

  Future<bool> _showThemedConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
  }) async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ColorUtils.hexToColor("C7DCFF"),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: ColorUtils.hexToColor("C7DCFF")),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: GradientHelper.mainGradient(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size.fromHeight(44),
                          ),
                          child: Text(
                            confirmText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return shouldProceed ?? false;
  }

  Future<void> _showLogoutConfirmDialog() async {
    final localizations = AppLocalizations.of(context);
    final shouldLogout = await _showThemedConfirmDialog(
      title: localizations.translate("logoutDialogTitle"),
      message: localizations.translate("logoutDialogMessage"),
      confirmText: localizations.translate("yes"),
      cancelText: localizations.translate("cancel"),
    );

    if (shouldLogout) {
      setState(() {
        _isProcessing = true;
      });
      final response = await _logoutService.logout();
      setState(() {
        _isProcessing = false;
      });

      final success = response["success"] == true;
      final message = (response["message"] as String?)?.trim();
      final snackBarText = success
          ? (message?.isNotEmpty == true
              ? message!
              : localizations.translate("logoutSuccess"))
          : (message?.isNotEmpty == true
              ? message!
              : localizations.translate("logoutFailed"));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackBarText)),
      );

      if (success) {
        _setGuestSessionWithoutNavigation();
      }
    }
  }

  Future<void> _showDeleteAccountConfirmDialog() async {
    final localizations = AppLocalizations.of(context);
    final shouldDelete = await _showThemedConfirmDialog(
      title: localizations.translate("deleteAccountDialogTitle"),
      message: localizations.translate("deleteAccountDialogMessage"),
      confirmText: localizations.translate("yes"),
      cancelText: localizations.translate("cancel"),
    );

    if (shouldDelete) {
      setState(() {
        _isProcessing = true;
      });
      final response = await _deleteAccountService.deleteAccount();
      setState(() {
        _isProcessing = false;
      });

      final success = response["success"] == true;
      final message = (response["message"] as String?)?.trim();
      final snackBarText = success
          ? (message?.isNotEmpty == true
              ? message!
              : localizations.translate("deleteAccountSuccess"))
          : (message?.isNotEmpty == true
              ? message!
              : localizations.translate("deleteAccountFailed"));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackBarText), 
        backgroundColor: success ? Colors.green : Colors.redAccent,
         duration: Duration(seconds: 3)),        
      );

      if (success) {
        _setGuestSessionWithoutNavigation();
        Navigator.pop(context); // Close profile screen after delete
      }
    }
  }

  void _handleAuthButtonTap() {
    if (_showGuestState) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }
    _showLogoutConfirmDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Image.asset('assets/menuicon/backarrow.png',
              height: 30, width: 30),
        ),
        title: Text(
          AppLocalizations.of(context).translate("menu"),
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _userCard(),
            const SizedBox(height: 20),
            _menuBox(context)
          ],
        ),
      ),
    );
  }

  Widget _userCard() {
    final localizations = AppLocalizations.of(context);
    final showGuestState = _showGuestState;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ColorUtils.hexToColor("C7DCFF"),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(showGuestState ? localizations.translate("guestUser") : _userName,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(showGuestState ? localizations.translate("guestEmail") : _userEmail,
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          _AuthActionButton(
            title: showGuestState
                ? localizations.translate("login")
                : localizations.translate("logout"),
            onTap: _handleAuthButtonTap,
          ),
        ],
      ),
    );
  }

  Widget _menuBox(BuildContext context) {
    final showGuestState = _showGuestState;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ColorUtils.hexToColor("C7DCFF"),
          width: 1,
        ),
      ),
      child: Column(
        children: [
         if(!PremiumState.isPremium.value) ...[ _menuTile("assets/menuicon/premium.png",
              AppLocalizations.of(context).translate("upgrade"), context, 0),
            ],
          _menuTile("assets/menuicon/above.png",
              AppLocalizations.of(context).translate("about"), context, 1),
          _menuTile("assets/menuicon/contactUS.png",
              AppLocalizations.of(context).translate("contactUs"), context, 2),
          _menuTile("assets/menuicon/privacyPolicy.png",
              AppLocalizations.of(context).translate("privacyPolicy"), context, 3),
          _menuTile("assets/menuicon/appLanguage.png",
              AppLocalizations.of(context).translate("appLanguage"), context, 4),
          if (!showGuestState)
            _menuTile(
              "assets/menuicon/deleteic.png",
              AppLocalizations.of(context).translate("deleteMyAccount"),
              context,
              5,
            ),
        ],
      ),
    );
  }

  Widget _menuTile(
    String iconName,
    String title,
    BuildContext context,
    int index, {
    IconData? leadingIcon,
  }) {
    return Column(
      children: [
        ListTile(
          leading: leadingIcon != null
              ? Icon(leadingIcon, size: 30, color: Colors.black87)
              : Image.asset(iconName, height: 30, width: 30),
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Colors.grey),
          onTap: () {
            if (index == 0) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SubscriptionScreen()));
            } 
            else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutAppScreen(),
                ),
              );
            }
            else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactUsScreen(),
                ),
              );
            }
            else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicyScreen(),
                ),
              );
            }
            else if (index == 4) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LanguageSelectionScreen(
                    changeLanguage: setLocale,
                    isFirstTime: false, // Important: Set to false when coming from menu
                  ),
                ),
              );
            }
            else if (index == 5) {
              _showDeleteAccountConfirmDialog();
            }
          },
        ),
        Container(
          height: 1,
          color: ColorUtils.hexToColor("C7DCFF"),
        ),
      ],
    );
  }
}

class _AuthActionButton extends StatelessWidget {
  const _AuthActionButton({required this.onTap, required this.title});

  final VoidCallback onTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: GradientHelper.mainGradient(),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        title,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ));
  }
}