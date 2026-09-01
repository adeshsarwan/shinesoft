import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/model/channel_guide_model.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:iptv_demo/utils/guide_live_progress.dart';
import 'package:shimmer/shimmer.dart';

/// Live EPG progress bar for home cards (value advances from guide start/stop).
class HomeChannelNowStrip extends StatefulWidget {
  const HomeChannelNowStrip({
    super.key,
    required this.channel,
    required this.controller,
    this.compact = false,
  });

  final IptvChannel channel;
  final IptvController controller;
  final bool compact;

  @override
  State<HomeChannelNowStrip> createState() => _HomeChannelNowStripState();
}

class _HomeChannelNowStripState extends State<HomeChannelNowStrip> {
  Timer? _tick;
  String? _tickedProgramId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.controller.prefetchHomeGuideIfNeeded(widget.channel));
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _ensureTicker(ChannelGuideProgram? cur) {
    final id = cur?.id.trim();
    final now = DateTime.now().toUtc();
    final live = cur != null && cur.stop.isAfter(now) && !now.isBefore(cur.start);
    if (!live || id == null || id.isEmpty) {
      _tick?.cancel();
      _tick = null;
      _tickedProgramId = null;
      return;
    }
    if (_tickedProgramId == id && _tick != null) return;
    _tick?.cancel();
    _tickedProgramId = id;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final key = widget.controller.guideLookupKey(widget.channel);
      final entry = widget.controller.homeGuideEntryByChannelId[key];
      final barHeight = widget.compact ? 3.h : 4.h;
      final topPad = widget.compact ? 4.h : 6.h;

      if (entry == null || entry.loading) {
        return Padding(
          padding: EdgeInsets.only(top: topPad),
          child: Shimmer.fromColors(
            baseColor: context.chipUnselectedBg,
            highlightColor: context.subtleTint,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(5.r),
              ),
            ),
          ),
        );
      }

      final cur = entry.current;
      if (cur == null) {
        return SizedBox(height: topPad);
      }

      _ensureTicker(cur);

      final live = GuideLiveProgress.compute(cur.start, cur.stop);
      final progress = live.progress.clamp(0.0, 1.0);

      return Padding(
        padding: EdgeInsets.only(top: topPad),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5.r),
          child: SizedBox(
            height: barHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: context.dividerColor),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    heightFactor: 1,
                    child: const ColoredBox(color: AppColors.linkBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
