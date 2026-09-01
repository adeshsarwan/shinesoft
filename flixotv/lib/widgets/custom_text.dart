import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? height;
  final TextDecoration? decoration;
  final FontStyle? fontStyle;
  final TextStyle? style;
  final double? letterSpacing;

  const CustomText(
    this.text, {
    super.key,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.fontFamily,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height,
    this.decoration,
    this.fontStyle,
    this.style,
    this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ??
        TextStyle(
          fontSize: fontSize ?? 14.sp,
          // Falls back to theme-aware textPrimary — works in both light & dark
          color: color ?? context.textPrimary,
          fontWeight: fontWeight ?? FontWeight.w500,
          fontFamily: fontFamily ?? AppStrings.interRegular,
          height: height,
          decoration: decoration,
          fontStyle: fontStyle,
        );
    final merged = letterSpacing != null
        ? baseStyle.copyWith(letterSpacing: letterSpacing)
        : baseStyle;
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines ?? 2,
      overflow: overflow ?? TextOverflow.ellipsis,
      style: merged,
    );
  }
}
