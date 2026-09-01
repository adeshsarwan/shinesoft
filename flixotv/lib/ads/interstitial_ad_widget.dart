import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iptv_demo/ads/interstitial_ad_manager.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class InterstitialAdScreen extends StatefulWidget {
  final VoidCallback onAdFinished;

  const InterstitialAdScreen({
    super.key,
    required this.onAdFinished,
  });

  @override
  State<InterstitialAdScreen> createState() => _InterstitialAdScreenState();
}

class _InterstitialAdScreenState extends State<InterstitialAdScreen> {
  bool _isWaiting = true;

  @override
  void initState() {
    super.initState();
    _playAd();
  }

  Future<void> _playAd() async {
    await InterstitialAdManager.instance.show(
      onDismissed: () {
        if (!mounted) return;
        widget.onAdFinished();
      },
    );
    if (!mounted) return;
    setState(() => _isWaiting = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isWaiting,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: Center(child: _buildLoadingUI()),
        ),
      ),
    );
  }

  Widget _buildLoadingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.white),
        20.verticalSpace,
        const CustomText(
          "Loading video ad...",
          color: AppColors.white,
          fontSize: 18,
          maxLines: 1,
        ),
        10.verticalSpace,
        const CustomText(
          "Please wait",
          color: AppColors.grey,
          maxLines: 1,
        ),
      ],
    );
  }
}
