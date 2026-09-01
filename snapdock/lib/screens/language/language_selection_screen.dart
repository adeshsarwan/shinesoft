import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/ads_services/banner_ads_service.dart';
import 'package:videodownloader/core/storage/shared_preferences/shared_prefs.dart';
import 'package:videodownloader/core/theme/color_utility.dart';
import 'package:videodownloader/l10n/app_localizations.dart';
import 'package:videodownloader/main.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final Function(Locale) changeLanguage;
  final bool isFirstTime;
  
  const LanguageSelectionScreen({
    super.key, 
    required this.changeLanguage,
    this.isFirstTime = false,
  });
  
  @override
  _LanguageSelectionScreenState createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final List<Map<String, String>> languages = [
    {"name": "English", "code": "en", "flag": "englishIcon.png"},
    {"name": "Filipino", "code": "fil", "flag": "filipicon.png"},
    {"name": "Hindi", "code": "hi", "flag": "hindiIcon.png"},
    {"name": "Japanese", "code": "ja", "flag": "japanIcon.png"},
    {"name": "Russian", "code": "ru", "flag": "russion.png"},
  ];

  String selectedLanguageCode = "en";
  bool isLanguageSelected = false;

  // Ads variables
  final BannerAdsService _adService = BannerAdsService();
  bool _isAdInitialized = false;
  bool _isBannerAdReady = false;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _initializeAds();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    String? savedLang = SharedPrefs.getData(PrefsConstants.selectedLanguage);
    if (savedLang != null && savedLang.isNotEmpty) {
      setState(() {
        selectedLanguageCode = savedLang;
        isLanguageSelected = true;
      });
    } else {
      // No saved language: default to English.
      // On first launch, keep the action button enabled immediately.
      setState(() {
        selectedLanguageCode = "en";
        isLanguageSelected = widget.isFirstTime;
      });

      if (widget.isFirstTime) {
        final defaultLocale = const Locale("en");
        appLocaleNotifier.value = defaultLocale;
        widget.changeLanguage(defaultLocale);
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  Future<void> _initializeAds() async {
    try {
      await _adService.initializeMobileAds();
      setState(() {
        _isAdInitialized = true;
      });

      _loadBannerAd();
    } catch (e) {
      print('Failed to initialize ads: $e');
    }
  }

  Future<void> _loadBannerAd() async {
    if (!_isAdInitialized) return;

    _bannerAd = await _adService.loadBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: () {
        setState(() {
          _isBannerAdReady = true;
        });
      },
      onAdFailedToLoad: (error) {
        setState(() {
          _isBannerAdReady = false;
        });
        print('Banner ad failed to load: $error');

        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) _loadBannerAd();
        });
      },
    );
  }

  void _onLanguageSelected(String languageCode) {
    setState(() {
      selectedLanguageCode = languageCode;
      isLanguageSelected = true;
    });
    
    print("selectedLanguageCode ===> $selectedLanguageCode");
    
    // Apply language change immediately for UI preview
    // but don't save or navigate yet
    final newLocale = Locale(selectedLanguageCode);
    appLocaleNotifier.value = newLocale;
    widget.changeLanguage(newLocale);
  }

  Future<void> _onSaveButtonPressed() async {
    if (!isLanguageSelected) return;
    
    // Save the language preference permanently
    SharedPrefs.saveData(
      PrefsConstants.selectedLanguage, 
      selectedLanguageCode
    );
    
    // Create the locale
    final newLocale = Locale(selectedLanguageCode);
    
    // Update global notifier
    appLocaleNotifier.value = newLocale;
    
    // Update via widget callback
    widget.changeLanguage(newLocale);
    
    // Navigate based on context
    if (widget.isFirstTime) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefsConstants.isLoggedIn, true);
      await prefs.setBool(PrefsConstants.isGuestUser, true);
      await prefs.setString(PrefsConstants.userName, "");
      await prefs.setString(PrefsConstants.userEmail, "");
      await prefs.setString(PrefsConstants.userToken, "");

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Language change from menu - go back
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate("changeLanguage"),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: !widget.isFirstTime ? IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset(
            'assets/menuicon/backarrow.png',
            height: 30,
            width: 30,
          ),
        ) : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context).translate("chooseYourLanguage"),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final language = languages[index];
                    final isSelected = language["code"] == selectedLanguageCode;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected
                              ? ColorUtils.primaryBlue
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: ListTile(
                          leading: Image.asset(
                            'assets/images/${language["flag"]!}',
                            height: 30,
                            width: 30,
                          ),
                          title: Text(
                            language["name"]!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            _onLanguageSelected(language["code"]!);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Save/Select Language Button
            BottomActionButton(
              text: widget.isFirstTime
                  ? AppLocalizations.of(context).translate("selectLanguage")
                  : AppLocalizations.of(context).translate("changeLanguage"),
              enabled: isLanguageSelected,
              onPressed: _onSaveButtonPressed,
            ),
            
            // Banner Ad
            if (_isBannerAdReady && mounted)
              Container(
                width: double.infinity,
                height: _bannerAd?.size.height.toDouble() ?? 50,
                alignment: Alignment.center,
                color: Colors.transparent,
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
}

class BottomActionButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback onPressed;

  const BottomActionButton({
    super.key,
    required this.text,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled 
                  ? ColorUtils.hexToColor("C94B9B") 
                  : Colors.grey.shade300,
              foregroundColor: enabled 
                  ? Colors.white 
                  : Colors.grey.shade500,
              elevation: enabled ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}