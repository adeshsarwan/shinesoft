import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:videodownloader/core/state/premium_state.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/ads_services/app_open_ads_service.dart';
import 'package:videodownloader/screens/language/language_selection_screen.dart';

class SpalshScreen extends StatefulWidget {
  const SpalshScreen({super.key});

  @override
  State<SpalshScreen> createState() => _SpalshScreenState();
}

class _SpalshScreenState extends State<SpalshScreen> {
  final AppOpenAdsService _appOpenAdsService = AppOpenAdsService();

  @override
  void initState() {
    super.initState();
    _showAdAndNavigate();
  }

  Future<void> _showAdAndNavigate() async {
    // Wait for splash screen to display (1 second)
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    final isPremiumSaved = prefs.getBool(PrefsConstants.isPremiumUser) ?? false;
    if (PremiumState.isPremium.value || isPremiumSaved) {
      print('⚠️ Premium user - skipping splash app-open ad');
      if (mounted) {
        _navigateToNextScreen();
      }
      return;
    }

    // Get ad stats for debugging
    final stats = await _appOpenAdsService.getStats();
    print('=== App Open Ad Stats ===');
    print('Open Count: ${stats['openCount']}');
    print('Is Ad Loaded: ${stats['isAdLoaded']}');
    print('Is Showing Ad: ${stats['isShowingAd']}');
    print('========================');

    // Ensure ad is loaded - wait longer for first load
    if (!_appOpenAdsService.isAdLoaded) {
      print('🔄 Loading app open ad...');
      try {
        final loaded = await _appOpenAdsService.preloadAd().timeout(
          const Duration(seconds: 10),
        );
        print('✅ App Open Ad load result: $loaded');
        if (!loaded) {
          print('❌ App Open Ad failed to load');
        }
      } catch (e) {
        print('❌ App Open Ad load timeout or error: $e');
      }
    } else {
      print('✅ App Open Ad already loaded');
    }

    // Try to show the ad
    // Add timeout to prevent hanging forever
    try {
      print('🎬 Attempting to show app open ad...');
      final adShown = await _appOpenAdsService.showAdIfAvailable().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ App Open Ad show timeout - proceeding to navigation');
          return false;
        },
      );
      print('✅ App Open Ad show result: $adShown');
      if (adShown) {
        print('✅ App Open Ad was shown and dismissed');
      } else {
        print('⚠️ App Open Ad was not shown');
      }
    } catch (e) {
      print('❌ Error showing app open ad: $e');
    }

    // Navigate after ad is dismissed or if ad wasn't shown
    if (mounted) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;

      final String? selectedLang = prefs.getString(PrefsConstants.selectedLanguage);
      if (selectedLang != null && selectedLang.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Language not selected, go to language selection with isFirstTime = true
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LanguageSelectionScreen(
              changeLanguage: (locale) {
                // This will be called but navigation happens in LanguageSelectionScreen
              },
              isFirstTime: true, // Important: Set to true for first time
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/spash.png"),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}