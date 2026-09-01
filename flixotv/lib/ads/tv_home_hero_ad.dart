import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:iptv_demo/ads/tv_home_ad_pool.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/utils/premium_access.dart';

/// TV home hero: loads one ad after the home screen is visible.
class TvHomeHeroAd extends StatefulWidget {
  const TvHomeHeroAd({super.key});

  @override
  State<TvHomeHeroAd> createState() => _TvHomeHeroAdState();
}

class _TvHomeHeroAdState extends State<TvHomeHeroAd> {
  final _pool = TvHomeAdPool.instance;

  @override
  void initState() {
    super.initState();
    _pool.addListener(_onPoolUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_pool.startWhenHomeVisible());
    });
  }

  void _onPoolUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pool.removeListener(_onPoolUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (Get.isRegistered<AuthService>()) {
        final auth = Get.find<AuthService>();
        auth.isPremiumUser.value;
        auth.isLoggedIn.value;
        auth.currentProfile.value;
        AdsVariable.isPurchased.value;
        auth.hasAdFreeAccess;
      } else {
        AdsVariable.isPurchased.value;
      }

      if (!shouldShowAdsToUser) return const SizedBox.shrink();

      if (_pool.hasAd) {
        switch (_pool.kind) {
          case TvHomeAdKind.banner:
            final ad = _pool.banner!;
            return SizedBox(
              width: double.infinity,
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            );
          case TvHomeAdKind.native:
            return SizedBox(
              width: double.infinity,
              height: 120,
              child: AdWidget(ad: _pool.native!),
            );
          case TvHomeAdKind.none:
            break;
        }
      }

      if (_pool.hasFailed && !_pool.hasAd) {
        return const SizedBox.shrink();
      }

      return const SizedBox(
        width: double.infinity,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    });
  }
}
