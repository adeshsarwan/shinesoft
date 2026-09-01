import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/ads/inline_ad_slot.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/ui/mobile/bottom_navigation.dart';
import 'package:iptv_demo/widgets/custom_text.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class ImportPlaylistScreen extends StatefulWidget {
  const ImportPlaylistScreen({super.key});

  @override
  State<ImportPlaylistScreen> createState() => _ImportPlaylistScreenState();
}

class _ImportPlaylistScreenState extends State<ImportPlaylistScreen> {
  final ScrollController _c1 = ScrollController();
  final ScrollController _c2 = ScrollController();
  final ScrollController _c3 = ScrollController();
  final channelController = Get.find<IptvController>();

  @override
  void initState() {
    super.initState();

    startScroll(_c1, left: true);
    startScroll(_c2, left: false);
    startScroll(_c3, left: true);
  }

  void startScroll(ScrollController controller, {required bool left}) {
    double offset = 0;

    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!controller.hasClients) return;

      offset += left ? 0.5 : -0.5;

      if (offset >= controller.position.maxScrollExtent) {
        offset = 0;
      } else if (offset <= 0) {
        offset = controller.position.maxScrollExtent;
      }

      controller.jumpTo(offset);
    });
  }

  Widget buildRow(ScrollController controller) {
    return SizedBox(
      height: 90.h,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        itemCount: channelController.visibleChannels.length * 10,
        itemBuilder: (context, index) {
          final logo = channelController
              .visibleChannels[index % channelController.visibleChannels.length]
              .logo;

          return Container(
            width: 100.w,
            margin: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Image.network(
                logo,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stackTrace) => const Icon(Icons.tv),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            80.verticalSpace,
            CustomText(
              AppStrings.importPlaylist,
              fontSize: 24.sp,
              fontFamily: AppStrings.interExtraBold,
              color: context.textPrimary,
              maxLines: 1,
            ),
            30.verticalSpace,
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 15.w),
              padding: EdgeInsets.all(20.h),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.importPlaylist,
                    fontSize: 16.sp,
                    fontFamily: AppStrings.interBold,
                    color: context.textPrimary,
                    maxLines: 1,
                  ),
                  CustomText(
                    AppStrings.addPlaylistHelp,
                    fontSize: 14.sp,
                    fontFamily: AppStrings.interRegular,
                    color: context.textSecondary,
                  ),
                  20.verticalSpace,
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      hintText: AppStrings.playlistHint,
                    ),
                  ),
                  20.verticalSpace,
                  Container(
                    height: 60.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18.r),
                      border: const GradientBoxBorder(
                        gradient: LinearGradient(
                          colors: AppColors.primaryGradient,
                        ),
                      ),
                    ),
                    child: Center(
                      child: GradientText(
                        AppStrings.importPlaylist,
                        colors: AppColors.primaryGradient,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontFamily: AppStrings.interBold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            25.verticalSpace,
            CustomText(
              AppStrings.startWatching,
              fontSize: 25.sp,
              fontFamily: AppStrings.interExtraBold,
              color: context.textPrimary,
              maxLines: 1,
            ),
            25.verticalSpace,
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 15.w),
              padding: EdgeInsets.all(15.h),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.yourChannels,
                    fontSize: 16.sp,
                    fontFamily: AppStrings.interBold,
                    color: context.textPrimary,
                    maxLines: 1,
                  ),
                  CustomText(
                    AppStrings.browseImportedChannels,
                    fontSize: 14.sp,
                    fontFamily: AppStrings.interRegular,
                    color: context.textSecondary,
                  ),
                  20.verticalSpace,
                  buildRow(_c1),
                  buildRow(_c2),
                  buildRow(_c3),
                  InkWell(
                    onTap: () => Get.to(() => const BottomNavigation()),
                    child: Container(
                      height: 70.h,
                      margin: EdgeInsets.symmetric(
                        horizontal: 15.w,
                        vertical: 15.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Center(
                        child: CustomText(
                          AppStrings.watchNow,
                          color: AppColors.white,
                          fontFamily: AppStrings.interBold,
                          fontSize: 20.sp,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            20.verticalSpace,
            const StackedAdFooter(),
            30.verticalSpace,
          ],
        ),
      ),
    );
  }
}
