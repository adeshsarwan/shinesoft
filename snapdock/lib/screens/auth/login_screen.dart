import 'package:flutter/material.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/storage/shared_preferences/shared_prefs.dart';
import 'package:videodownloader/core/theme/color_utility.dart';
import 'package:videodownloader/l10n/app_localizations.dart';
import 'package:videodownloader/screens/auth/forgot_password_screen.dart';
import 'package:videodownloader/screens/auth/signup_screen.dart';
import 'package:videodownloader/screens/home_screen/home_screen.dart';
import 'package:videodownloader/services/api_client/api_client.dart';
import 'package:videodownloader/services/auth_services/login_service/login_service.dart';
import 'package:videodownloader/services/stripe_services/get_subscription_service/get_subscription_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordObscured = true;
  final LoginService _loginService = LoginService(apiClient: ApiClient());
  final GetSubscriptionService _getSubscriptionService =
      GetSubscriptionService(apiClient: ApiClient());

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: ColorUtils.hexToColor("C94B9B"),
          width: 1.5,
        ),
      ),
    );
  }

  void _handleForgotPasswordTap() {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate("loginTitle"),
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset(
            'assets/menuicon/backarrow.png',
            height: 30,
            width: 30,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate("welcomeBack"),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate("signInSubtitle"),
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final email = value?.trim() ?? "";
                      if (email.isEmpty) {
                        return localizations.translate("emailRequired");
                      }
                      if (!_isValidEmail(email)) {
                        return localizations.translate("pleaseEnterValidEmail");
                      }
                      return null;
                    },
                    decoration: _buildInputDecoration(
                      hintText: localizations.translate("email"),
                      prefixIcon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.translate("passwordRequired");
                      }
                      return null;
                    },
                    decoration: _buildInputDecoration(
                      hintText: localizations.translate("password"),
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                        icon: Icon(
                          _isPasswordObscured
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPasswordTap,
                      child: Text(
                        localizations.translate("forgotPassword"),
                        style: TextStyle(
                          color: ColorUtils.hexToColor("C94B9B"),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: GradientHelper.mainGradient(),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        final localizations = AppLocalizations.of(context);
                        FocusScope.of(context).unfocus();
                        if (_formKey.currentState?.validate() ?? false) {
                          final response = await _loginService.loginUser(
                            email,
                            password,
                          );
                          if (response["success"] == true) {
                            final root = response["data"] as Map<String, dynamic>?;
                            print("LoginScreen: raw login response data = $root");
                            // API may wrap actual user payload under a nested "data" key.
                            final data = (root != null && root["data"] is Map<String, dynamic>)
                                ? root["data"] as Map<String, dynamic>
                                : root;
                            print("LoginScreen: effective payload for tokens = $data");
                            SharedPrefs.saveData(
                              PrefsConstants.isLoggedIn,
                              true,
                            );
                            SharedPrefs.saveData(
                              PrefsConstants.isGuestUser,
                              false,
                            );
                            SharedPrefs.saveData(
                              PrefsConstants.userEmail,
                              email,
                            );
                            if (data != null) {
                              final userName = (data["username"] ?? data["name"]) as String?;
                              final tokenMap = data["token"] is Map<String, dynamic>
                                  ? data["token"] as Map<String, dynamic>
                                  : null;
                              final dynamic tokenScalar =
                                  data["token"] is String ? data["token"] : null;
                              final accessToken = (data["access_token"] ??
                                      data["access"] ??
                                      tokenMap?["access_token"] ??
                                      tokenMap?["access"] ??
                                      tokenScalar) as String?;
                              final refreshToken = (data["refresh_token"] ??
                                      data["refresh"] ??
                                      tokenMap?["refresh_token"] ??
                                      tokenMap?["refresh"]) as String?;

                              print("LoginScreen: parsed userName=$userName");
                              print("LoginScreen: parsed accessToken=$accessToken");
                              print("LoginScreen: parsed refreshToken=$refreshToken");

                              if (userName != null && userName.trim().isNotEmpty) {
                                SharedPrefs.saveData(
                                  PrefsConstants.userName,
                                  userName.trim(),
                                );
                              }
                              if (accessToken != null && accessToken.isNotEmpty) {
                                SharedPrefs.saveData(PrefsConstants.accessToken, accessToken);
                                // Refresh premium state from backend right after login.
                                await _getSubscriptionService.syncPremiumStateFromSubscription();
                              }
                              if (refreshToken != null && refreshToken.isNotEmpty) {
                                SharedPrefs.saveData(PrefsConstants.refreshToken, refreshToken);
                              }

                              print("LoginScreen: stored accessToken=${SharedPrefs.getData(PrefsConstants.accessToken)}");
                              print("LoginScreen: stored refreshToken=${SharedPrefs.getData(PrefsConstants.refreshToken)}");
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localizations.translate("loginSuccess"),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePageScreen(),
                              ),
                            );
                          } else {
                            final errorMessage =
                                (response["message"] as String?)?.trim();
                            final statusCode = response["statusCode"];
                          final userFacingError =
                              (errorMessage == null || errorMessage.isEmpty)
                                  ? localizations.translate("failedToLogin")
                                  : errorMessage;
                            print(
                              "Login User Error [$statusCode]: $userFacingError",
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text(
                                  userFacingError,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }
                          return;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        localizations.translate("login"),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: localizations.translate("noAccountPrompt"),
                            ),
                            TextSpan(
                              text: localizations.translate("signUpHere"),
                              style: TextStyle(
                                color: ColorUtils.hexToColor("C94B9B"),
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
