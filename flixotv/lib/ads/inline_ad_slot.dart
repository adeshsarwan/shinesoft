import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:iptv_demo/ads/banner_ad_widget.dart';
import 'package:iptv_demo/ads/native_ad_widget.dart';

/// Alternates native and banner inline ads (even slot = native, odd = banner).
class InlineAdSlot extends StatelessWidget {
  final int slotIndex;
  final double horizontal;
  final double vertical;

  const InlineAdSlot({
    super.key,
    required this.slotIndex,
    this.horizontal = 12,
    this.vertical = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (!AdsVariable.shouldShowAds) return const SizedBox.shrink();

    final child = slotIndex.isEven
        ? const NativeAdWidget()
        : const BannerAdWidget();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal.w,
        vertical: vertical.h,
      ),
      child: child,
    );
  }
}

/// Stacked native + banner for screen footers (settings, profile, etc.).
class StackedAdFooter extends StatelessWidget {
  final double horizontal;

  const StackedAdFooter({super.key, this.horizontal = 12});

  @override
  Widget build(BuildContext context) {
    if (!AdsVariable.shouldShowAds) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal.w),
      child: const Column(
        children: [
          BannerAdWidget(),
        ],
      ),
    );
  }
}
