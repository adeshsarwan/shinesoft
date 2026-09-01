import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:iptv_demo/utils/post_auth_home_route.dart';

/// Resolves banner ad unit + size: TV uses Google's adaptive test unit.
class AdBannerSizeResolver {
  AdBannerSizeResolver._();

  static Future<ResolvedBannerConfig> resolve({
    required BuildContext context,
    required String fixedBannerUnitId,
    required String adaptiveBannerUnitId,
    bool preferLandscape = false,
  }) async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final isTv = await isAndroidTvLeanbackDevice();

    if (!isTv) {
      return ResolvedBannerConfig(
        adUnitId: fixedBannerUnitId,
        size: AdSize.banner,
        mode: BannerLoadMode.fixed,
      );
    }

    AdSize size;
    if (preferLandscape) {
      size = await AdSize.getAnchoredAdaptiveBannerAdSize(
            Orientation.landscape,
            width,
          ) ??
          AdSize.banner;
    } else {
      size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            width,
          ) ??
          AdSize.banner;
    }

    return ResolvedBannerConfig(
      adUnitId: adaptiveBannerUnitId,
      size: size,
      mode: BannerLoadMode.adaptive,
    );
  }
}

enum BannerLoadMode { fixed, adaptive }

class ResolvedBannerConfig {
  ResolvedBannerConfig({
    required this.adUnitId,
    required this.size,
    required this.mode,
  });

  final String adUnitId;
  final AdSize size;
  final BannerLoadMode mode;
}
