import 'package:flutter/material.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/storage/shared_preferences/shared_prefs.dart';
import 'package:videodownloader/core/theme/color_utility.dart';
import 'package:videodownloader/l10n/app_localizations.dart';
import 'package:videodownloader/screens/home_screen/home_screen.dart';
import 'package:videodownloader/services/api_client/api_client.dart';
import 'package:videodownloader/services/auth_services/register_user_service/register_user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final RegisterUserService _registerUserService = RegisterUserService(apiClient: ApiClient());
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
        borderSide: BorderSide(color: ColorUtils.hexToColor("C94B9B"), width: 1.5),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _handleGuestContinueTap() {
    final localizations = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    SharedPrefs.saveData(PrefsConstants.isLoggedIn, true);
    SharedPrefs.saveData(PrefsConstants.isGuestUser, true);
    SharedPrefs.saveData(PrefsConstants.userName, "");
    SharedPrefs.saveData(PrefsConstants.userEmail, "");
    SharedPrefs.saveData(PrefsConstants.userToken, "");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizations.translate("guestAccountCreatedSuccess"),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePageScreen()),
    );
  }

  Future<void> _handleCreateAccountTap() async {
    final name = _userNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final localizations = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              localizations.translate("passwordsDoNotMatch"),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
        return;
      }
      final response = await _registerUserService.registerUser(
        name,
        email,
        password,
      );
      if (response["success"] == true) {
        final root = response["data"] as Map<String, dynamic>?;
        print("SignupScreen: raw register data = $root");
        // API may wrap actual user payload under nested "data".
        final data = (root != null && root["data"] is Map<String, dynamic>)
            ? root["data"] as Map<String, dynamic>
            : root;
        print("SignupScreen: effective payload for tokens = $data");
        SharedPrefs.saveData(PrefsConstants.isLoggedIn, true);
        SharedPrefs.saveData(PrefsConstants.isGuestUser, false);
        SharedPrefs.saveData(
          PrefsConstants.userName,
          _userNameController.text.trim(),
        );
        SharedPrefs.saveData(
          PrefsConstants.userEmail,
          _emailController.text.trim(),
        );
        if (data != null) {
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

          print("SignupScreen: parsed accessToken=$accessToken");
          print("SignupScreen: parsed refreshToken=$refreshToken");

          if (accessToken != null && accessToken.isNotEmpty) {
            SharedPrefs.saveData(PrefsConstants.accessToken, accessToken);
          }
          if (refreshToken != null && refreshToken.isNotEmpty) {
            SharedPrefs.saveData(PrefsConstants.refreshToken, refreshToken);
          }

          print("SignupScreen: stored accessToken=${SharedPrefs.getData(PrefsConstants.accessToken)}");
          print("SignupScreen: stored refreshToken=${SharedPrefs.getData(PrefsConstants.refreshToken)}");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate("createAccountSuccess"),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePageScreen()),
        );
      } else {
        final errorMessage = (response["message"] as String?)?.trim();
        final statusCode = response["statusCode"];
        final userFacingError =
            (errorMessage == null || errorMessage.isEmpty)
                ? localizations.translate("failedToCreateAccount")
                : errorMessage;
        print("Register User Error [$statusCode]: $userFacingError");
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
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
    appBar: AppBar(
        title: Text(
          localizations.translate("signUpTitle"),
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
                    localizations.translate("createAccount"),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate("signUpSubtitle"),
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.translate("usernameRequired");
                      }
                      return null;
                    },
                    controller: _userNameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    decoration: _buildInputDecoration(
                      hintText: localizations.translate("userName"),
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _buildInputDecoration(
                      hintText: localizations.translate("email"),
                      prefixIcon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.translate("passwordRequired");
                      }
                      if (value.length < 8) {
                        return localizations.translate("passwordMustBeAtLeast8CharactersLong");
                      }
                      return null;
                    },
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
                    textInputAction: TextInputAction.done,
                    maxLength: 8,
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
                          _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.translate("confirmPasswordRequired");
                      }
                      if (value != _passwordController.text) {
                        return localizations.translate("passwordsDoNotMatch");
                      }
                      return null;
                    },
                    controller: _confirmPasswordController,
                    obscureText: _isConfirmPasswordObscured,
                    textInputAction: TextInputAction.done,
                    maxLength: 8,
                    decoration: _buildInputDecoration(
                      hintText: localizations.translate("confirmPassword"),
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                          });
                        },
                        icon: Icon(
                          _isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: GradientHelper.mainGradient(),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: _handleCreateAccountTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        localizations.translate("createAccount"),
                        style: const TextStyle(
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
                      onPressed: _handleGuestContinueTap,
                      child: Text(
                        localizations.translate("continueWithGuestUser"),
                        style: TextStyle(
                          color: ColorUtils.hexToColor("C94B9B"),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
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
}