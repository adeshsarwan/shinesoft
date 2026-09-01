import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/static_locale_data.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final iptv = Get.find<IptvController>();
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.appIconColor,
            size: 20.sp,
          ),
          onPressed: () => Get.back(),
        ),
        title: CustomText(
          AppStrings.selectLanguage,
          color: context.textPrimary,
          fontSize: 18.sp,
          fontFamily: AppStrings.interSemiBold,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final current = iptv.selectedLanguage.value;
        final items =
            iptv.availableLanguages.isNotEmpty ? iptv.availableLanguages : kStaticLanguages;
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          itemCount: items.length,
          separatorBuilder: (_, __) => 12.verticalSpace,
          itemBuilder: (ctx, i) {
            final item = items[i];
            final selected = current == item.id;
            return GestureDetector(
              onTap: () async {
                await iptv.setLanguageFilter(item.id);
                if (ctx.mounted) Get.back();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : context.settingsTileBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: selected ? AppColors.primary : context.borderColor,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        item.label,
                        fontSize: 16.sp,
                        fontFamily: AppStrings.interSemiBold,
                        color: context.textPrimary,
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 22.sp),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
