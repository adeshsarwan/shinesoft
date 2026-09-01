import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:iptv_demo/ui/mobile/channel_schedule_screen.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

/// In-player channel schedule drawer for TV — uses the same guides API as mobile.
class ChannelScheduleOverlayTv extends StatefulWidget {
  const ChannelScheduleOverlayTv({
    super.key,
    required this.channel,
    required this.onClose,
  });

  final IptvChannel channel;
  final VoidCallback onClose;

  @override
  State<ChannelScheduleOverlayTv> createState() =>
      _ChannelScheduleOverlayTvState();
}

class _ChannelScheduleOverlayTvState extends State<ChannelScheduleOverlayTv> {
  late final String _controllerTag;
  late final ChannelScheduleController _controller;

  final _focusClose = FocusNode(debugLabel: 'schedule_close');
  final _focusRetry = FocusNode(debugLabel: 'schedule_retry');
  final _focusLoadMore = FocusNode(debugLabel: 'schedule_load_more');
  final List<FocusNode> _dayFocusNodes = [];
  final List<FocusNode> _programFocusNodes = [];
  final _listScroll = ScrollController();

  int _focusedDayIndex = 0;
  int _focusedProgramIndex = -1; // -1 = sidebar has focus
  bool _initialFocusDone = false;

  @override
  void initState() {
    super.initState();
    final ch = widget.channel;
    _controllerTag = 'tv_sch_${ch.favoriteKey.hashCode}_${ch.hashCode}';
    final controllerExisted =
        Get.isRegistered<ChannelScheduleController>(tag: _controllerTag);
    if (controllerExisted) {
      _controller = Get.find<ChannelScheduleController>(tag: _controllerTag);
    } else {
      _controller = Get.put(
        ChannelScheduleController(ch, isTvHost: true),
        tag: _controllerTag,
      );
    }
    // Match mobile: today in local calendar + fresh guides (correct times / NOW).
    _controller.selectedScheduleDay =
        ChannelScheduleController.dateOnlyLocal(DateTime.now());
    unawaited(_controller.loadGuides());
    _syncDayFocusNodes();
  }

  @override
  void dispose() {
    _focusClose.dispose();
    _focusRetry.dispose();
    _focusLoadMore.dispose();
    for (final n in _dayFocusNodes) {
      n.dispose();
    }
    for (final n in _programFocusNodes) {
      n.dispose();
    }
    _listScroll.dispose();
    super.dispose();
  }

  void _syncDayFocusNodes() {
    final count = _controller.selectableScheduleDays.length;
    while (_dayFocusNodes.length < count) {
      _dayFocusNodes.add(FocusNode(debugLabel: 'schedule_day'));
    }
    while (_dayFocusNodes.length > count) {
      _dayFocusNodes.removeLast().dispose();
    }
    final selected = _controller.selectedScheduleDay;
    final days = _controller.selectableScheduleDays;
    _focusedDayIndex = days.indexWhere(
      (d) => ChannelScheduleController.dateOnlyLocal(d) ==
          ChannelScheduleController.dateOnlyLocal(selected),
    );
    if (_focusedDayIndex < 0) _focusedDayIndex = 0;
  }

  void _syncProgramFocusNodes(int count) {
    while (_programFocusNodes.length < count) {
      _programFocusNodes.add(FocusNode(debugLabel: 'schedule_program'));
    }
    while (_programFocusNodes.length > count) {
      _programFocusNodes.removeLast().dispose();
    }
  }

  List<_TvScheduleEntry> _entries(ChannelScheduleController c) {
    final items = <_TvScheduleEntry>[];
    if (c.currentRow != null) {
      items.add(_TvScheduleEntry(isNow: true, row: c.currentRow!));
    }
    for (final item in c.upcomingItems) {
      items.add(
        _TvScheduleEntry(
          isNow: false,
          row: item.row,
          sectionTitle: item.sectionTitle,
        ),
      );
    }
    return items;
  }

  void _selectDay(int index, ChannelScheduleController c) {
    final days = c.selectableScheduleDays;
    if (index < 0 || index >= days.length) return;
    setState(() {
      _focusedDayIndex = index;
      _focusedProgramIndex = -1;
    });
    c.setSelectedScheduleDay(days[index]);
    _syncDayFocusNodes();
  }

  void _requestProgramFocus(int index) {
    if (index < 0 || index >= _programFocusNodes.length) return;
    setState(() => _focusedProgramIndex = index);
    _programFocusNodes[index].requestFocus();
  }

  void _requestDayFocus(int index) {
    if (index < 0 || index >= _dayFocusNodes.length) return;
    setState(() => _focusedProgramIndex = -1);
    _dayFocusNodes[index].requestFocus();
  }

  KeyEventResult _onOverlayKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      widget.onClose();
      return KeyEventResult.handled;
    }

    final entries = _entries(_controller);
    final onSidebar = _focusedProgramIndex < 0;

    if (key == LogicalKeyboardKey.arrowRight && onSidebar) {
      if (entries.isNotEmpty) {
        _requestProgramFocus(0);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft && !onSidebar) {
      _requestDayFocus(_focusedDayIndex);
      return KeyEventResult.handled;
    }

    if (onSidebar) {
      if (key == LogicalKeyboardKey.arrowDown &&
          _focusedDayIndex < _dayFocusNodes.length - 1) {
        _requestDayFocus(_focusedDayIndex + 1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp && _focusedDayIndex > 0) {
        _requestDayFocus(_focusedDayIndex - 1);
        return KeyEventResult.handled;
      }
    } else {
      if (key == LogicalKeyboardKey.arrowDown &&
          _focusedProgramIndex < entries.length - 1) {
        _requestProgramFocus(_focusedProgramIndex + 1);
        _scrollProgramIntoView(_focusedProgramIndex + 1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        if (_focusedProgramIndex > 0) {
          _requestProgramFocus(_focusedProgramIndex - 1);
          _scrollProgramIntoView(_focusedProgramIndex - 1);
        } else {
          _requestDayFocus(_focusedDayIndex);
        }
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _scrollProgramIntoView(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listScroll.hasClients) return;
      if (index < 0 || index >= _programFocusNodes.length) return;
      final ctx = _programFocusNodes[index].context;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.18,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChannelScheduleController>(
      tag: _controllerTag,
      init: _controller,
      global: false,
      builder: (c) {
        _syncDayFocusNodes();
        final entries = _entries(c);
        _syncProgramFocusNodes(entries.length);

        if (!_initialFocusDone && !c.loading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _initialFocusDone) return;
            _initialFocusDone = true;
            if (entries.isNotEmpty) {
              _requestProgramFocus(0);
            } else if (_dayFocusNodes.isNotEmpty) {
              _requestDayFocus(_focusedDayIndex);
            } else {
              _focusClose.requestFocus();
            }
          });
        }

        return Focus(
          autofocus: true,
          onKeyEvent: _onOverlayKey,
          child: Material(
            color: AppColors.black.withValues(alpha: 0.78),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(c),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDaySidebar(c),
                        Expanded(child: _buildProgramPanel(c, entries)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ChannelScheduleController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 12),
      child: Row(
        children: [
          const CustomText(
            'Channel Schedule',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
            maxLines: 1,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomText(
              '${c.channel.titleWithLanguage} · ${c.dateLabel}',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.white.withValues(alpha: 0.55),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _TvOverlayBtn(
            focusNode: _focusClose,
            onPressed: widget.onClose,
            child: const Icon(Icons.close, color: AppColors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySidebar(ChannelScheduleController c) {
    final days = c.selectableScheduleDays;
    return Container(
      width: 200,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.white.withValues(alpha: 0.12)),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 12, 24),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final selected =
              ChannelScheduleController.dateOnlyLocal(day) ==
                  ChannelScheduleController.dateOnlyLocal(
                    c.selectedScheduleDay,
                  );
          final label = c.shortLabelForScheduleDay(day);
          final programCount = selected && !c.loading
              ? _entries(c).length
              : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _TvOverlayBtn(
              focusNode: _dayFocusNodes[index],
              onPressed: () => _selectDay(index, c),
              onFocus: () {
                setState(() {
                  _focusedDayIndex = index;
                  _focusedProgramIndex = -1;
                });
              },
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      label,
                      fontSize: selected ? 18 : 16,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.white
                          : AppColors.white.withValues(alpha: 0.45),
                      maxLines: 1,
                    ),
                  ),
                  if (programCount != null && programCount > 0) ...[
                    const SizedBox(width: 6),
                    CustomText(
                      '$programCount',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white.withValues(alpha: 0.5),
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgramPanel(
    ChannelScheduleController c,
    List<_TvScheduleEntry> entries,
  ) {
    if (c.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }
    if (c.error != null) {
      return _buildError(c);
    }
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CustomText(
            c.guideChannelId.isEmpty
                ? 'Schedule is available for channels from the catalog.'
                : 'No programs in the guide for this day.',
            textAlign: TextAlign.center,
            fontSize: 16,
            color: AppColors.white.withValues(alpha: 0.65),
            maxLines: 4,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _listScroll,
      padding: const EdgeInsets.fromLTRB(24, 8, 32, 32),
      itemCount: entries.length + (c.hasMoreGuide ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= entries.length) {
          return _buildLoadMore(c);
        }
        final entry = entries[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.sectionTitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: CustomText(
                  entry.sectionTitle!,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppStrings.interSemiBold,
                  color: AppColors.white.withValues(alpha: 0.65),
                  maxLines: 1,
                ),
              ),
            _buildProgramCard(c, entry, index),
          ],
        );
      },
    );
  }

  Widget _buildProgramCard(
    ChannelScheduleController c,
    _TvScheduleEntry entry,
    int index,
  ) {
    final row = entry.row;
    final logo = c.channel.logo.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _TvOverlayBtn(
        focusNode: _programFocusNodes[index],
        onPressed: () {
          if (!entry.isNow && c.programForReminder(row) != null) {
            c.toggleProgramNotification(row);
          }
        },
        onFocus: () => setState(() => _focusedProgramIndex = index),
        expand: true,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _programThumbnail(logo, c.logoInitials, entry.isNow),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          row.title,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppStrings.interBold,
                          color: AppColors.white,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.isNow) _nowBadge(),
                      if (!entry.isNow && c.programForReminder(row) != null)
                        _reminderIcon(c, row),
                    ],
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    row.timeRange,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withValues(alpha: 0.55),
                    maxLines: 1,
                  ),
                  if (entry.isNow &&
                      row.subtitle != null &&
                      row.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    CustomText(
                      row.subtitle!,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white.withValues(alpha: 0.65),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (entry.isNow && row.progress != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: row.progress!.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor:
                            AppColors.white.withValues(alpha: 0.15),
                        color: AppColors.linkBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (row.elapsedLabel != null)
                          CustomText(
                            row.elapsedLabel!,
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.5),
                            maxLines: 1,
                          ),
                        if (row.leftLabel != null)
                          CustomText(
                            row.leftLabel!,
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.5),
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _programThumbnail(String logoUrl, String initials, bool isNow) {
    return Container(
      width: 140,
      height: 84,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: isNow
            ? Border.all(color: AppColors.linkBlue, width: 2)
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (logoUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _thumbFallback(initials),
            )
          else
            _thumbFallback(initials),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbFallback(String initials) {
    return Center(
      child: CustomText(
        initials,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        fontFamily: AppStrings.interExtraBold,
        color: AppColors.white.withValues(alpha: 0.35),
        maxLines: 1,
      ),
    );
  }

  Widget _nowBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.liveBadgeBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const CustomText(
        'NOW',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
        maxLines: 1,
      ),
    );
  }

  Widget _reminderIcon(ChannelScheduleController c, ScheduleRow row) {
    final program = c.programForReminder(row);
    if (program == null) return const SizedBox.shrink();

    final key = c.notificationKeyFor(program.programStartTime);
    final on = c.isReminderScheduled(row);
    final busy = c.notificationTogglingKey == key;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
          : Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: on
                    ? AppColors.linkBlue.withValues(alpha: 0.22)
                    : AppColors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: on
                      ? AppColors.linkBlue
                      : AppColors.white.withValues(alpha: 0.38),
                  width: 1.4,
                ),
              ),
              child: Icon(
                on ? Icons.notifications_active : Icons.notifications_none,
                color: on ? AppColors.linkBlue : AppColors.white70,
                size: 20,
              ),
            ),
    );
  }

  Widget _buildLoadMore(ChannelScheduleController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: c.loadingMore
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : _TvOverlayBtn(
                focusNode: _focusLoadMore,
                onPressed: c.loadMoreGuides,
                child: const CustomText(
                  'Load more',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.linkBlue,
                  maxLines: 1,
                ),
              ),
      ),
    );
  }

  Widget _buildError(ChannelScheduleController c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const CustomText(
            'Couldn\'t load the schedule',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          CustomText(
            c.error ?? '',
            textAlign: TextAlign.center,
            fontSize: 13,
            color: AppColors.white.withValues(alpha: 0.55),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          _TvOverlayBtn(
            focusNode: _focusRetry,
            onPressed: c.loadGuides,
            child: const CustomText(
              'Try again',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TvScheduleEntry {
  const _TvScheduleEntry({
    required this.isNow,
    required this.row,
    this.sectionTitle,
  });

  final bool isNow;
  final ScheduleRow row;
  final String? sectionTitle;
}

class _TvOverlayBtn extends StatefulWidget {
  const _TvOverlayBtn({
    required this.focusNode,
    required this.onPressed,
    required this.child,
    this.onFocus,
    this.expand = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  final FocusNode focusNode;
  final VoidCallback onPressed;
  final VoidCallback? onFocus;
  final Widget child;
  final bool expand;
  final EdgeInsets padding;

  @override
  State<_TvOverlayBtn> createState() => _TvOverlayBtnState();
}

class _TvOverlayBtnState extends State<_TvOverlayBtn> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: widget.expand ? double.infinity : null,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: _focused
            ? AppColors.white.withValues(alpha: 0.22)
            : AppColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: _focused
            ? Border.all(color: AppColors.white, width: 2)
            : Border.all(color: AppColors.transparent, width: 2),
      ),
      child: widget.child,
    );

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (f) {
        setState(() => _focused = f);
        if (f) widget.onFocus?.call();
      },
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        final k = e.logicalKey;
        if (k == LogicalKeyboardKey.select ||
            k == LogicalKeyboardKey.enter ||
            k == LogicalKeyboardKey.space) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: content,
      ),
    );
  }
}
