import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/model/channel_guide_model.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:iptv_demo/model/channel_program.dart';
import 'package:iptv_demo/repositories/iptv_repository.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/services/notification_service.dart';
import 'package:iptv_demo/ui/tv/widgets/tv_top_nav.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';
import 'package:iptv_demo/utils/guide_live_progress.dart';
import 'package:iptv_demo/widgets/schedule_notification_login_dialog.dart';

class _ChannelScheduleRow {
  _ChannelScheduleRow({
    required this.channel,
    required this.programs,
    this.isLoading = false,
  });

  final IptvChannel channel;
  final List<ChannelGuideProgram> programs;
  final bool isLoading;
}

class ScheduleTvScreen extends StatefulWidget {
  const ScheduleTvScreen({super.key});

  @override
  State<ScheduleTvScreen> createState() => _ScheduleTvScreenState();
}

class _ScheduleTvScreenState extends State<ScheduleTvScreen> {
  final Map<int, bool> _programFocused = {};
  final Map<String, bool> _scheduledByKey = {};
  final Map<String, bool> _scheduleCheckLoaded = {};

  List<_ChannelScheduleRow> _rows = [];
  static const int _pageSize = 12;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _isTogglingNotification = false;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  String _scheduleKey(String channelDbId, String programStartTime) =>
      '$channelDbId|$programStartTime';

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);

    final controller = Get.find<IptvController>();
    final iptvRepo = Get.find<IptvRepository>();
    final allChannels = controller.filteredChannels
        .where((c) => c.dbId.isNotEmpty)
        .toList();

    final totalPages =
        allChannels.isEmpty ? 0 : (allChannels.length / _pageSize).ceil();

    if (mounted) {
      setState(() {
        _totalPages = totalPages;
        if (_totalPages == 0) {
          _currentPage = 0;
        } else if (_currentPage >= _totalPages) {
          _currentPage = _totalPages - 1;
        }
      });
    }

    if (allChannels.isEmpty) {
      if (mounted) {
        setState(() {
          _rows = [];
          _isLoading = false;
        });
      }
      return;
    }

    final startIndex = (_currentPage * _pageSize).clamp(0, allChannels.length);
    final channels = allChannels
        .skip(startIndex)
        .take(_pageSize)
        .toList();

    final rows = <_ChannelScheduleRow>[];
    for (final channel in channels) {
      rows.add(_ChannelScheduleRow(channel: channel, programs: const [], isLoading: true));
    }
    if (mounted) {
      setState(() {
        _rows = rows;
        _isLoading = false;
      });
    }

    final authHeaders = _authHeaders();

    for (var i = 0; i < channels.length; i++) {
      final channel = channels[i];
      var programs = <ChannelGuideProgram>[];

      try {
        programs = await _fetchTodayGuidePrograms(
          iptvRepo,
          channel,
          headers: authHeaders,
        );
      } catch (e) {
        debugPrint('[ScheduleTv] guides for ${channel.title}: $e');
      }

      if (!mounted) return;
      setState(() {
        if (i < _rows.length) {
          _rows[i] = _ChannelScheduleRow(
            channel: channel,
            programs: programs,
          );
        }
      });

      if (programs.isNotEmpty) {
        await _prefetchScheduleStatus(channel.dbId, programs);
      }
    }
  }

  Map<String, String>? _authHeaders() {
    if (!Get.isRegistered<AuthService>()) return null;
    final auth = Get.find<AuthService>();
    if (!auth.isLoggedIn.value || auth.accessToken.value.isEmpty) return null;
    return auth.authHeaders;
  }

  String _guideChannelId(IptvChannel channel) {
    final id = channel.streamChannelId;
    if (id.isNotEmpty) return id;
    return channel.feedId.trim();
  }

  /// Same guides API + local calendar day as mobile channel schedule.
  Future<List<ChannelGuideProgram>> _fetchTodayGuidePrograms(
    IptvRepository repo,
    IptvChannel channel, {
    Map<String, String>? headers,
  }) async {
    final guideId = _guideChannelId(channel);
    final dbId = channel.dbId.trim();
    if (guideId.isEmpty || dbId.isEmpty) return [];

    final date = guidesApiDateParamForLocalDay(DateTime.now());
    final data = await repo.fetchChannelGuides(
      guideId,
      dbId,
      limit: 16,
      date: date,
      headers: headers,
    );

    final nowUtc = DateTime.now().toUtc();
    final slots = <ChannelGuideProgram>[];
    final seen = <String>{};

    void add(ChannelGuideProgram? p) {
      if (p == null) return;
      final key =
          '${p.start.toUtc().millisecondsSinceEpoch}|${p.stop.toUtc().millisecondsSinceEpoch}|${p.title}';
      if (seen.contains(key)) return;
      if (!p.stop.isAfter(nowUtc)) return;
      seen.add(key);
      slots.add(p);
    }

    add(data.current);
    for (final p in data.upcoming) {
      add(p);
    }

    slots.sort((a, b) => a.start.compareTo(b.start));
    return slots;
  }

  ChannelProgram _guideProgramToNotification(ChannelGuideProgram p) {
    return ChannelProgram(
      showId: p.id,
      showTitle: p.title,
      programStartTime: p.start.toUtc().toIso8601String(),
      programEndTime: p.stop.toUtc().toIso8601String(),
    );
  }

  Future<void> _refreshScheduleChecksAfterLogin() async {
    if (!Get.find<AuthService>().isLoggedIn.value) return;
    _scheduleCheckLoaded.clear();
    for (final row in _rows) {
      if (row.channel.dbId.isEmpty || row.programs.isEmpty) continue;
      await _prefetchScheduleStatus(row.channel.dbId, row.programs);
    }
  }

  Future<void> _prefetchScheduleStatus(
    String channelDbId,
    List<ChannelGuideProgram> programs,
  ) async {
    final notifications = Get.find<NotificationService>();
    for (final guide in programs) {
      final program = _guideProgramToNotification(guide);
      final key = _scheduleKey(channelDbId, program.programStartTime);
      if (_scheduleCheckLoaded.containsKey(key)) continue;

      final (scheduled, _) = await notifications.isProgramNotificationScheduled(
        channelId: channelDbId,
        programStartTime: program.programStartTime,
      );
      if (!mounted) return;
      setState(() {
        _scheduleCheckLoaded[key] = true;
        _scheduledByKey[key] = scheduled;
      });
    }
  }

  Future<void> _toggleProgramNotification({
    required IptvChannel channel,
    required ChannelGuideProgram guide,
  }) async {
    final program = _guideProgramToNotification(guide);
    final auth = Get.find<AuthService>();
    if (!auth.isLoggedIn.value) {
      if (!mounted) return;
      await promptLoginForScheduleNotification(
        context,
        isTvHost: true,
        onSessionEstablished: _refreshScheduleChecksAfterLogin,
      );
      return;
    }

    if (channel.dbId.isEmpty) {
      showAppToast(
        title: 'Unavailable',
        message: 'This channel cannot be scheduled',
        isError: true,
      );
      return;
    }

    if (_isTogglingNotification) return;
    setState(() => _isTogglingNotification = true);

    final notifications = Get.find<NotificationService>();
    final key = _scheduleKey(channel.dbId, program.programStartTime);
    var isScheduled = _scheduledByKey[key] ?? false;

    if (!_scheduleCheckLoaded.containsKey(key)) {
      final (checked, err) = await notifications.isProgramNotificationScheduled(
        channelId: channel.dbId,
        programStartTime: program.programStartTime,
      );
      if (err.isNotEmpty && !checked) {
        showAppToast(title: 'Error', message: err, isError: true);
        setState(() => _isTogglingNotification = false);
        return;
      }
      isScheduled = checked;
      _scheduleCheckLoaded[key] = true;
    }

    late final bool success;
    late final String message;

    if (isScheduled) {
      (success, message) = await notifications.cancelProgramNotification(
        channelId: channel.dbId,
        programStartTime: program.programStartTime,
      );
    } else {
      (success, message) = await notifications.scheduleProgramNotification(
        program: program,
        channelId: channel.dbId,
        channelName: channel.title,
      );
    }

    if (!mounted) return;
    setState(() {
      _isTogglingNotification = false;
      if (success) {
        _scheduledByKey[key] = !isScheduled;
      }
    });

    showAppToast(
      title: success ? 'Notifications' : 'Error',
      message: message,
      isError: !success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tvScaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNav(),
            Expanded(child: _buildScheduleBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return TvTopNav(
      selectedIndex: 1,
      categories: const [],
      onTabSelected: (i) {
        if (i != 1) Get.offNamed(AppRoutes.HOME_TV);
      },
      onSearchPressed: () => Get.offNamed(AppRoutes.HOME_TV),
      onSignInPressed: () => Get.toNamed(AppRoutes.LOGIN),
    );
  }

  Widget _buildScheduleBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rows.isEmpty) {
      return Center(
        child: CustomText(
          'No channels available for schedule',
          fontSize: 16,
          color: context.tvSubtitleColor,
          fontFamily: AppStrings.interMedium,
        ),
      );
    }

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildSectionTitle(context)),
              _buildPaginationControls(context),
            ],
          ),
          20.verticalSpace,
          for (var i = 0; i < _rows.length; i++) ...[
            _buildScheduleRow(context, _rows[i], i),
            10.verticalSpace,
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return CustomText(
      'TV Schedule',
      fontSize: 28,
      color: context.tvSectionTitleColor,
      fontWeight: FontWeight.w700,
      fontFamily: AppStrings.interBold,
      maxLines: 1,
    );
  }

  Widget _buildPaginationControls(BuildContext context) {
    if (_totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final canGoPrev = _currentPage > 0 && !_isLoading;
    final canGoNext = _currentPage < _totalPages - 1 && !_isLoading;

    return Row(
      children: [
        TextButton(
          onPressed: canGoPrev
              ? () {
                  setState(() {
                    _currentPage--;
                  });
                  _loadSchedules();
                }
              : null,
          child: CustomText(
            'Previous',
            fontSize: 14,
            fontFamily: AppStrings.interSemiBold,
            color:
                canGoPrev ? context.tvSectionTitleColor : context.tvSubtitleColor,
            maxLines: 1,
          ),
        ),
        8.horizontalSpace,
        CustomText(
          '${_currentPage + 1} / $_totalPages',
          fontSize: 13,
          fontFamily: AppStrings.interMedium,
          color: context.tvSubtitleColor,
          maxLines: 1,
        ),
        8.horizontalSpace,
        TextButton(
          onPressed: canGoNext
              ? () {
                  setState(() {
                    _currentPage++;
                  });
                  _loadSchedules();
                }
              : null,
          child: CustomText(
            'Next',
            fontSize: 14,
            fontFamily: AppStrings.interSemiBold,
            color:
                canGoNext ? context.tvSectionTitleColor : context.tvSubtitleColor,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(
    BuildContext context,
    _ChannelScheduleRow row,
    int rowIndex,
  ) {
    return Container(
      decoration: _scheduleRowDecoration(context),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _buildChannelNameCell(context, row.channel.titleWithLanguage),
          12.horizontalSpace,
          Expanded(
            child: row.isLoading
                ? const SizedBox(
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _buildProgramStrip(context, row, rowIndex),
          ),
        ],
      ),
    );
  }

  BoxDecoration _scheduleRowDecoration(BuildContext context) {
    return BoxDecoration(
      color: context.tvCardBg,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.05),
          blurRadius: 4,
        ),
      ],
    );
  }

  Widget _buildChannelNameCell(BuildContext context, String channelName) {
    return SizedBox(
      width: 186,
      child: CustomText(
        channelName,
        fontSize: 14,
        color: context.tvSectionTitleColor,
        fontWeight: FontWeight.w600,
        fontFamily: AppStrings.interSemiBold,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildProgramStrip(
    BuildContext context,
    _ChannelScheduleRow row,
    int rowIndex,
  ) {
    if (row.programs.isEmpty) {
      return CustomText(
        'No programs',
        fontSize: 13,
        color: context.tvSubtitleColor,
        fontFamily: AppStrings.interRegular,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < row.programs.length; i++) ...[
            if (i > 0) 6.horizontalSpace,
            _buildProgramBlock(
              context,
              channel: row.channel,
              program: row.programs[i],
              blockId: rowIndex * 10 + i,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgramBlock(
    BuildContext context, {
    required IptvChannel channel,
    required ChannelGuideProgram program,
    required int blockId,
  }) {
    final focused = _programFocused[blockId] ?? false;
    final startIso = program.start.toUtc().toIso8601String();
    final scheduleKey = _scheduleKey(channel.dbId, startIso);
    final isScheduled = _scheduledByKey[scheduleKey] ?? false;
    final timeLabel = formatGuideTimeRange(program.start, program.stop);
    final canNotify = channel.dbId.isNotEmpty;
    final isScheduledWhenLoggedIn =
        Get.find<AuthService>().isLoggedIn.value && isScheduled;
    void activateProgram() {
      unawaited(
        _toggleProgramNotification(
          channel: channel,
          guide: program,
        ),
      );
    }

    return FocusableActionDetector(
      onFocusChange: (f) {
        setState(() {
          if (f) {
            _programFocused[blockId] = true;
          } else {
            _programFocused.remove(blockId);
          }
        });
      },
      actions: canNotify
          ? {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  activateProgram();
                  return null;
                },
              ),
            }
          : const {},
      shortcuts: canNotify
          ? const {
              SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            }
          : const {},
      child: GestureDetector(
        onTap: canNotify ? activateProgram : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: _programBlockDecoration(
            context,
            focused,
            canNotify && isScheduledWhenLoggedIn,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canNotify) ...[
                Icon(
                  isScheduledWhenLoggedIn
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  size: 16,
                  color: isScheduledWhenLoggedIn
                      ? AppColors.tvBannerFocus
                      : context.tvSubtitleColor,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      timeLabel,
                      fontSize: 12,
                      color: focused
                          ? AppColors.tvBannerFocus
                          : context.tvSubtitleColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppStrings.interSemiBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.verticalSpace,
                    CustomText(
                      program.title,
                      fontSize: 15,
                      color: focused
                          ? AppColors.tvBannerFocus
                          : context.tvSectionTitleColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppStrings.interSemiBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _programBlockDecoration(
    BuildContext context,
    bool focused,
    bool isScheduled,
  ) {
    return BoxDecoration(
      color: focused
          ? context.tvFocusPillBg
          : isScheduled
              ? AppColors.tvBannerFocus.withValues(alpha: 0.12)
              : context.chipUnselectedBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: focused || isScheduled
            ? AppColors.tvBannerFocus
            : context.cardBorderColor,
        width: focused ? 2 : 1,
      ),
    );
  }
}
