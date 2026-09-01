import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';

void showAppToast({
  required String title,
  required String message,
  bool isError = false,
}) {
  if (isError) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.danger,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
    return;
  }

  final accent = isError ? AppColors.danger : AppColors.primary;
  final normalizedTitle = title.trim().toLowerCase();
  final normalizedMessage = message.trim().toLowerCase();
  final displayText = normalizedMessage.startsWith(normalizedTitle)
      ? message
      : '$title: $message';

  Get.rawSnackbar(
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    borderRadius: 12,
    backgroundColor: AppColors.transparent,
    padding: EdgeInsets.zero,
    isDismissible: true,
    duration: const Duration(seconds: 2),
    messageText: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.2),
      ),
      child: Text(
        displayText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
