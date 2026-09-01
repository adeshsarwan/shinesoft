import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/static_locale_data.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/model/country_item.dart';
import 'package:iptv_demo/repositories/iptv_repository.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class CountrySelectScreen extends StatefulWidget {
  const CountrySelectScreen({super.key});

  @override
  State<CountrySelectScreen> createState() => _CountrySelectScreenState();
}

class _CountrySelectScreenState extends State<CountrySelectScreen> {
  List<CountryItem> _countries = <CountryItem>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final res = await Get.find<IptvRepository>().fetchCountries();
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        _countries = parseCountriesFromApiBody(res.body);
      }
    } catch (_) {
      _countries = <CountryItem>[];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
          AppStrings.selectCountry,
          color: context.textPrimary,
          fontSize: 18.sp,
          fontFamily: AppStrings.interSemiBold,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            )
          : _countries.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: CustomText(
                      'No countries available from API.',
                      textAlign: TextAlign.center,
                      color: context.textSecondary,
                      fontSize: 14.sp,
                      fontFamily: AppStrings.interRegular,
                    ),
                  ),
                )
          : Obx(() {
              final current = iptv.selectedCountryCode.value.toUpperCase();
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                itemCount: _countries.length,
                separatorBuilder: (_, __) => 12.verticalSpace,
                itemBuilder: (ctx, i) {
                  final item = _countries[i];
                  final selected = current == item.code.toUpperCase();
                  return GestureDetector(
                    onTap: () async {
                      await iptv.setCountryFilter(item.code);
                      if (ctx.mounted) Get.back();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : context.settingsTileBg,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : context.borderColor,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 28.h,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.chipUnselectedBg,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: CustomText(
                              item.flag,
                              fontSize: 12.sp,
                              fontFamily: AppStrings.interSemiBold,
                              color: context.textPrimary,
                            ),
                          ),
                          12.horizontalSpace,
                          Expanded(
                            child: CustomText(
                              item.name,
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
