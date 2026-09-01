import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/model/channel_guide_model.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:iptv_demo/model/channel_program.dart';
import 'package:iptv_demo/repositories/iptv_repository.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/services/notification_service.dart';
import 'package:iptv_demo/ads/inline_ad_slot.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';
import 'package:iptv_demo/utils/guide_live_progress.dart';
import 'package:iptv_demo/utils/notification_platform.dart';
import 'package:iptv_demo/widgets/schedule_notification_login_dialog.dart';

/// Single entry for navigation (named route or imperative push).
void openChannelSchedule(IptvChannel channel) {
  Get.toNamed(AppRoutes.CHANNEL_SCHEDULE, arguments: channel);
}

// —— Data (kept in this file; not split into models/mapper/widgets) ——————————

class ScheduleRow {
  const ScheduleRow({
    required this.timeRange,
    required this.title,
    this.subtitle,
    this.elapsedLabel,
    this.leftLabel,
    this.progress,
    this.isActive = false,
    this.reminderProgramId,
    this.reminderProgramStartUtc,
    this.reminderProgramStopUtc,
    this.isNotificationScheduled = false,
  });

  final String timeRange;
  final String title;
  final String? subtitle;
  final String? elapsedLabel;
  final String? leftLabel;
  final double? progress;
  final bool isActive;

  /// When set, the bell uses server notification APIs for this program.
  final String? reminderProgramId;
  final DateTime? reminderProgramStartUtc;
  final DateTime? reminderProgramStopUtc;

  /// Initial bell state from guides API `isScheduled`.
  final bool isNotificationScheduled;
}

/// One visible row plus an optional day-part heading (Morning / Afternoon / …).
class ScheduleTimelineItem {
  const ScheduleTimelineItem({this.sectionTitle, required this.row});

  final String? sectionTitle;
  final ScheduleRow row;
}

// —— GetX ———————————————————————————————————————————————————————————————————

class ChannelScheduleController extends GetxController {
  ChannelScheduleController(
    this.channel, {
    this.isTvHost = false,
  });

  /// Guides list is chronological from midnight; need enough rows to reach "now" and beyond.
  /// Changed from 20 to 10 for better pagination experience
  static const int guidePageSize = 10;

  final IptvChannel channel;

  /// When true, login prompt uses the TV auth dialog instead of the mobile route.
  final bool isTvHost;

  bool loading = true;
  bool loadingMore = false;
  String? error;
  ScheduleRow? currentRow;
  List<ScheduleTimelineItem> upcomingItems = [];
  
  String dateLabel = 'Today';
  bool hasMoreGuide = false;

  /// Server notification scheduled state keyed by program start ISO UTC.
  final Map<String, bool> notificationScheduled = {};

  /// Only the bell for this program key shows a spinner while toggling.
  String? notificationTogglingKey;
  bool _isPromptingLogin = false;

  /// How many upcoming rows we ask the API for (pagination); not the filtered count.
  int _guideListRequestLimit = guidePageSize;

  /// ScrollController for detecting pagination scroll position
  ScrollController? _scrollController;

  /// Whether scroll listener is attached
  bool _scrollListenerAttached = false;

  /// Last guides API payload; reused to refresh NOW / upcoming as time passes.
  ChannelGuideData? _cachedGuideData;

  Timer? _liveRefreshTimer;

  /// Max interval between UI refreshes (progress + NOW / upcoming).
  static const Duration _liveRefreshInterval = Duration(minutes: 1);

  /// Minimum delay so we do not spin timers when boundaries are very close.
  static const Duration _liveRefreshMinInterval = Duration(seconds: 5);

  /// Local calendar day for the schedule list.
  late DateTime selectedScheduleDay;

  static DateTime _dateOnlyLocal(DateTime dt) {
    final l = dt.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  static DateTime get _todayLocal {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime get _tomorrowLocal =>
      _todayLocal.add(const Duration(days: 1));

  /// Local calendar day for the guides API (`YYYY-MM-DD`).
  String get _guidesApiDateParam =>
      guidesApiDateParamForLocalDay(selectedScheduleDay);

  String get guideChannelId {
    final id = channel.streamChannelId;
    if (id.isNotEmpty) return id;
    return channel.feedId.trim();
  }

  /// Mongo `_id` for notification schedule / cancel / check APIs.
  String get notificationChannelId => channel.dbId.trim();

  /// Path segment for `GET /guides/{channelId}/{channelDbId}`.
  String get guidesApiChannelDbId {
    final dbId = notificationChannelId;
    if (dbId.isNotEmpty) return dbId;
    return guideChannelId;
  }

  /// Whether this row can show the reminder bell (upcoming program with guide data).
  bool showsReminderBell(ScheduleRow row) => programForReminder(row) != null;

  bool get isLoggedInForNotifications =>
      Get.isRegistered<AuthService>() &&
      Get.find<AuthService>().isLoggedIn.value;

  bool get canScheduleNotifications {
    if (!isLoggedInForNotifications || notificationChannelId.isEmpty) {
      return false;
    }
    if (isTvHost) {
      return isTvPushRegisteredWithServer;
    }
    return true;
  }

  String get logoInitials => _initials(channel.title);

  Map<String, String>? _authHeaders() {
    if (!Get.isRegistered<AuthService>()) return null;
    final auth = Get.find<AuthService>();
    if (!auth.isLoggedIn.value || auth.accessToken.value.isEmpty) return null;
    return auth.authHeaders;
  }

  String _notificationKey(String programStartIso) =>
      '$notificationChannelId|$programStartIso';

  @override
  void onInit() {
    selectedScheduleDay = _dateOnlyLocal(DateTime.now());
    super.onInit();
    loadGuides();
  }

  @override
  void onClose() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = null;
    _detachScrollListener();
    _scrollController?.dispose();
    _scrollController = null;
    super.onClose();
  }

  /// Attach scroll controller for pagination detection
  void attachScrollController(ScrollController controller) {
    _scrollController = controller;
    _attachScrollListener();
  }

  void _attachScrollListener() {
    if (_scrollListenerAttached || _scrollController == null) return;
    _scrollController!.addListener(_onScrollEvent);
    _scrollListenerAttached = true;
  }

  void _detachScrollListener() {
    if (!_scrollListenerAttached || _scrollController == null) return;
    _scrollController!.removeListener(_onScrollEvent);
    _scrollListenerAttached = false;
  }

  /// Called when user scrolls; triggers pagination near bottom
  void _onScrollEvent() {
    if (_scrollController == null || loading || loadingMore || !hasMoreGuide) {
      return;
    }

    final position = _scrollController!.position;
    
    /// Trigger load when user has scrolled to 80% of content
    final scrollThreshold = position.maxScrollExtent * 0.8;
    
    if (position.pixels >= scrollThreshold) {
      debugPrint('Pagination trigger: scrolled to ${(position.pixels / position.maxScrollExtent * 100).toStringAsFixed(1)}%');
      unawaited(loadMoreGuides());
    }
  }

  bool get _isSelectedDayToday =>
      _dateOnlyLocal(selectedScheduleDay) == _todayLocal;

  void _syncLiveRefreshTimer() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = null;
    if (!_isSelectedDayToday || _cachedGuideData == null) return;
    // Apply immediately so we are not waiting for the first periodic tick.
    _tickLiveSchedule(reschedule: false);
    _scheduleNextLiveTick();
  }

  void _scheduleNextLiveTick() {
    _liveRefreshTimer?.cancel();
    if (!_isSelectedDayToday || _cachedGuideData == null) return;
    _liveRefreshTimer = Timer(_delayUntilNextScheduleEvent(), () {
      _tickLiveSchedule();
    });
  }

  /// Next refresh at the sooner of: next program start/stop, or [_liveRefreshInterval].
  Duration _delayUntilNextScheduleEvent() {
    final now = DateTime.now().toUtc();
    var next = now.add(_liveRefreshInterval);

    void consider(DateTime instant) {
      if (instant.isAfter(now) && instant.isBefore(next)) {
        next = instant;
      }
    }

    final data = _cachedGuideData;
    if (data != null) {
      final cur = data.current;
      if (cur != null) {
        consider(cur.start.toUtc());
        final stop = cur.stop.toUtc();
        consider(stop);
        // Nudge after end time so a slightly slow device clock still advances NOW.
        consider(stop.add(const Duration(seconds: 1)));
      }
      for (final p in data.upcoming) {
        consider(p.start.toUtc());
        final stop = p.stop.toUtc();
        consider(stop);
        consider(stop.add(const Duration(seconds: 1)));
      }
    }

    final delay = next.difference(now);
    if (delay < _liveRefreshMinInterval) return _liveRefreshMinInterval;
    if (delay > _liveRefreshInterval) return _liveRefreshInterval;
    return delay;
  }

  void _tickLiveSchedule({bool reschedule = true}) {
    if (!_isSelectedDayToday) {
      _syncLiveRefreshTimer();
      return;
    }
    final cached = _cachedGuideData;
    if (cached == null || loading) return;
    _applyGuideData(cached);
    update();
    if (reschedule) _scheduleNextLiveTick();
  }

  /// Schedule is limited to today and tomorrow (local calendar).
  static DateTime get _schedulePickerFirstLocal => _todayLocal;
  static DateTime get _schedulePickerLastLocal => _tomorrowLocal;

  /// Shared with TV schedule overlay (same date bounds as mobile picker).
  static DateTime get schedulePickerFirst => _schedulePickerFirstLocal;
  static DateTime get schedulePickerLast => _schedulePickerLastLocal;

  static DateTime dateOnlyLocal(DateTime dt) => _dateOnlyLocal(dt);

  List<DateTime> get selectableScheduleDays {
    final days = <DateTime>[];
    var d = schedulePickerFirst;
    final last = schedulePickerLast;
    while (!d.isAfter(last)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    return days;
  }

  String labelForScheduleDay(DateTime day) =>
      _scheduleDateHeading(_dateOnlyLocal(day));

  String shortLabelForScheduleDay(DateTime day) {
    final d = _dateOnlyLocal(day);
    if (d == _todayLocal) return 'Today';
    if (d == _tomorrowLocal) return 'Tomorrow';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  String notificationKeyFor(String programStartIso) =>
      _notificationKey(programStartIso);

  ChannelProgram? programForReminder(ScheduleRow row) =>
      _programForNotification(row);

  bool isReminderScheduled(ScheduleRow row) {
    final program = programForReminder(row);
    if (program == null) {
      return row.isNotificationScheduled;
    }
    final key = notificationKeyFor(program.programStartTime);
    return notificationScheduled[key] ?? row.isNotificationScheduled;
  }

  void setSelectedScheduleDay(DateTime day) {
    var d = _dateOnlyLocal(day);
    if (d.isBefore(_todayLocal)) d = _todayLocal;
    if (d.isAfter(_schedulePickerLastLocal)) d = _schedulePickerLastLocal;
    if (d == selectedScheduleDay) return;
    selectedScheduleDay = d;
    _syncLiveRefreshTimer();
    loadGuides();
  }

  Future<void> loadGuides({bool silent = false}) async {
  if (!silent) {
    loading = true;
    loadingMore = false;
    error = null;

    /// Reset pagination
    _guideListRequestLimit = guidePageSize;

    update();
  }

  final guideId = guideChannelId;
  final channelDbId = guidesApiChannelDbId;

  if (guideId.isEmpty || channelDbId.isEmpty) {
    loading = false;
    _cachedGuideData = null;
    _syncLiveRefreshTimer();
    currentRow = null;
    upcomingItems = [];
    hasMoreGuide = false;
    dateLabel = _scheduleDateHeadingForSelectedDay();

    update();
    return;
  }

  try {
    final data = await Get.find<IptvRepository>().fetchChannelGuides(
      guideId,
      channelDbId,
      limit: _guideListRequestLimit,
      date: _guidesApiDateParam,
      headers: _authHeaders(),
    );

    _cachedGuideData = data;

    /// Apply filtering + mapping
    _applyGuideData(data);

    dateLabel = _scheduleDateHeadingForSelectedDay();

    /// IMPORTANT FIX
    /// If API returned exactly limit count,
    /// assume more data exists
    hasMoreGuide = data.upcoming.length == _guideListRequestLimit;

    loading = false;
    error = null;

    _syncLiveRefreshTimer();

    update();

    /// IMPORTANT FIX
    /// Auto-load more if visible filtered items are too less
    if (!silent &&
        upcomingItems.length < 10 &&
        hasMoreGuide &&
        _guideListRequestLimit < 300) {
      await loadMoreGuides();
    }
  } catch (e, st) {
    debugPrint('ChannelScheduleController: $e\n$st');

    if (!silent) {
      loading = false;
      error = e.toString();

      update();
    }
  }
}

  Future<void> loadMoreGuides() async {
  final guideId = guideChannelId;
  final channelDbId = guidesApiChannelDbId;

  if (guideId.isEmpty ||
      channelDbId.isEmpty ||
      !hasMoreGuide ||
      loading ||
      loadingMore) {
    return;
  }

  loadingMore = true;

  /// Increase limit
  _guideListRequestLimit += guidePageSize;

  update();

  try {
    final data = await Get.find<IptvRepository>().fetchChannelGuides(
      guideId,
      channelDbId,
      limit: _guideListRequestLimit,
      date: _guidesApiDateParam,
      headers: _authHeaders(),
    );

    _cachedGuideData = data;

    /// Rebuild visible items
    _applyGuideData(data);

    dateLabel = _scheduleDateHeadingForSelectedDay();

    /// IMPORTANT FIX
    hasMoreGuide = data.upcoming.length == _guideListRequestLimit;

    loadingMore = false;
    error = null;

    _syncLiveRefreshTimer();

    update();
  } catch (e, st) {
    debugPrint('ChannelScheduleController loadMore: $e\n$st');

    /// rollback limit
    _guideListRequestLimit -= guidePageSize;

    loadingMore = false;

    update();
  }
}

  /// Local-time bucket label for the start of a program.
  static String dayPartTitle(DateTime localStart) {
    final h = localStart.hour;
    if (h >= 21 || h < 5) return 'Night';
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  void _applyGuideData(ChannelGuideData data) {
    final dayStart = selectedScheduleDay;
    final dayEnd = dayStart.add(const Duration(days: 1));
    final isCalendarToday = _dateOnlyLocal(dayStart) == _todayLocal;
    final nowUtc = DateTime.now().toUtc();

    bool isPastForTodayView(DateTime stopUtc) =>
        isCalendarToday && !stopUtc.isAfter(nowUtc);

    bool programOverlapsSelectedDay(DateTime startUtc, DateTime stopUtc) {
      final s = startUtc.toLocal();
      final e = stopUtc.toLocal();
      return s.isBefore(dayEnd) && e.isAfter(dayStart);
    }

    bool upcomingStartsOnSelectedDay(DateTime startUtc) {
      return _dateOnlyLocal(startUtc) == dayStart;
    }

    String dedupeKey(ChannelGuideProgram p) {
      final t = p.title.trim().toLowerCase();
      return '${p.start.toUtc().millisecondsSinceEpoch}|'
          '${p.stop.toUtc().millisecondsSinceEpoch}|$t';
    }

    bool isAiringNow(ChannelGuideProgram p) {
      if (!programOverlapsSelectedDay(p.start, p.stop)) return false;
      final startUtc = p.start.toUtc();
      final stopUtc = p.stop.toUtc();
      return !nowUtc.isBefore(startUtc) && nowUtc.isBefore(stopUtc);
    }

    ChannelGuideProgram? currentProgram;
    if (isCalendarToday) {
      final candidates = <ChannelGuideProgram>[
        if (data.current != null) data.current!,
        ...data.upcoming,
      ];
      for (final p in candidates) {
        if (!isAiringNow(p)) continue;
        if (currentProgram == null ||
            p.start.toUtc().isAfter(currentProgram.start.toUtc())) {
          currentProgram = p;
        }
      }
    }
    if (currentProgram != null) {
      currentRow = _mapCurrentProgram(currentProgram);
    } else {
      currentRow = null;
    }

    final currentId = currentProgram?.id.trim() ?? '';
    final currentDedupe =
        currentProgram != null ? dedupeKey(currentProgram) : null;

    final upcoming = <ChannelGuideProgram>[];
    final seenUpcoming = <String>{};
    if (currentDedupe != null) seenUpcoming.add(currentDedupe);

    for (final p in data.upcoming) {
      if (!upcomingStartsOnSelectedDay(p.start)) continue;
      if (isPastForTodayView(p.stop)) continue;
      if (currentId.isNotEmpty && p.id.trim() == currentId) continue;
      final dk = dedupeKey(p);
      if (currentDedupe != null && dk == currentDedupe) continue;
      if (seenUpcoming.contains(dk)) continue;

      // Below NOW: starts when current ends (inclusive) or later today.
      if (currentProgram != null) {
        if (p.start.toUtc().isBefore(currentProgram.stop.toUtc())) continue;
      } else if (isCalendarToday && !p.start.toUtc().isAfter(nowUtc)) {
        continue;
      }

      seenUpcoming.add(dk);
      upcoming.add(p);
    }

    upcoming.sort((a, b) => a.start.compareTo(b.start));

    final items = <ScheduleTimelineItem>[];
    String? lastPart;
    for (final p in upcoming) {
      final part = dayPartTitle(guideDisplayLocal(p.start));
      items.add(
        ScheduleTimelineItem(
          sectionTitle: part != lastPart ? part : null,
          row: _mapUpcomingProgram(p),
        ),
      );
      lastPart = part;
    }
    upcomingItems = items;
    _seedNotificationStateFromGuideData(data);
  }

  /// Bell icons use `isScheduled` from the guides API (no per-row check API).
  void _seedNotificationStateFromGuideData(ChannelGuideData data) {
    notificationScheduled.clear();

    void seedProgram(ChannelGuideProgram p) {
      final id = p.id.trim();
      if (id.isEmpty) return;
      final key = _notificationKey(p.start.toUtc().toIso8601String());
      notificationScheduled[key] = p.isScheduled;
    }

    final cur = data.current;
    if (cur != null) seedProgram(cur);
    for (final p in data.upcoming) {
      seedProgram(p);
    }
  }

  ChannelProgram? _programForNotification(ScheduleRow row) {
    final showId = row.reminderProgramId;
    final start = row.reminderProgramStartUtc;
    final stop = row.reminderProgramStopUtc;
    if (showId == null || start == null || stop == null) return null;
    return ChannelProgram(
      showId: showId,
      showTitle: row.title,
      programStartTime: start.toUtc().toIso8601String(),
      programEndTime: stop.toUtc().toIso8601String(),
    );
  }

  Future<void> toggleProgramNotification(ScheduleRow row) async {
    if (notificationTogglingKey != null) return;

    if (!Get.isRegistered<AuthService>() ||
        !Get.find<AuthService>().isLoggedIn.value) {
      if (_isPromptingLogin) return;
      final ctx = Get.context;
      if (ctx == null || !ctx.mounted) return;
      _isPromptingLogin = true;
      await promptLoginForScheduleNotification(
        ctx,
        isTvHost: isTvHost,
        onSessionEstablished: () => unawaited(loadGuides(silent: true)),
      );
      _isPromptingLogin = false;
      return;
    }

    if (isTvHost && !isTvPushRegisteredWithServer) {
      showAppToast(
        title: 'TV notifications',
        message:
            'Sign out and sign in again on this TV to enable program notifications.',
        isError: true,
      );
      return;
    }

    if (notificationChannelId.isEmpty) {
      showAppToast(
        title: 'Unavailable',
        message: 'Notifications are not available for this channel',
        isError: true,
      );
      return;
    }

    final program = _programForNotification(row);
    if (program == null) return;

    final now = DateTime.now().toUtc();
    final startUtc = DateTime.tryParse(program.programStartTime)?.toUtc();
    if (startUtc != null && !startUtc.isAfter(now)) {
      showAppToast(
        title: 'Cannot remind',
        message: 'This program has already started',
        isError: true,
      );
      return;
    }

    if (!Get.isRegistered<NotificationService>()) return;

    final notifications = Get.find<NotificationService>();
    final key = _notificationKey(program.programStartTime);
    notificationTogglingKey = key;
    update();

    final isScheduled =
        notificationScheduled[key] ?? row.isNotificationScheduled;

    late final bool success;
    late final String message;

    if (isScheduled) {
      (success, message) = await notifications.cancelProgramNotification(
        channelId: notificationChannelId,
        programStartTime: program.programStartTime,
      );
    } else {
      (success, message) = await notifications.scheduleProgramNotification(
        program: program,
        channelId: notificationChannelId,
        channelName: channel.titleWithLanguage,
      );
    }

    notificationTogglingKey = null;
    if (success) {
      notificationScheduled[key] = !isScheduled;
      // Sync bell state from guides `isScheduled` when the backend has updated.
      unawaited(loadGuides(silent: true));
    }
    update();

    showAppToast(
      title: success ? 'Notifications' : 'Error',
      message: message,
      isError: !success,
    );
  }

  String _scheduleDateHeadingForSelectedDay() {
    return _scheduleDateHeading(selectedScheduleDay);
  }

  String _scheduleDateHeading(DateTime refLocalDay) {
    final d = _dateOnlyLocal(refLocalDay);
    final today = _todayLocal;
    final tomorrow = _tomorrowLocal;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[d.month - 1];
    if (d == today) return 'Today, $m ${d.day}';
    if (d == tomorrow) return 'Tomorrow, $m ${d.day}';
    return '$m ${d.day}, ${d.year}';
  }

  ScheduleRow _mapCurrentProgram(ChannelGuideProgram p) {
    final range = formatGuideTimeRange(p.start, p.stop);
    final live = GuideLiveProgress.compute(p.start, p.stop);
    final progress = live.progress;
    final elapsedLabel = live.elapsedLabel;
    final leftLabel = live.leftLabel;
    final desc = p.description.trim();
    final id = p.id.trim();
    return ScheduleRow(
      timeRange: range,
      title: p.title,
      subtitle: desc.isEmpty ? null : desc,
      elapsedLabel: elapsedLabel,
      leftLabel: leftLabel,
      progress: progress,
      isActive: true,
      reminderProgramId: id.isEmpty ? null : id,
      reminderProgramStartUtc: id.isEmpty ? null : p.start,
      reminderProgramStopUtc: id.isEmpty ? null : p.stop,
      isNotificationScheduled: p.isScheduled,
    );
  }

  ScheduleRow _mapUpcomingProgram(ChannelGuideProgram p) {
    final range = formatGuideTimeRange(p.start, p.stop);
    final desc = p.description.trim();
    final id = p.id.trim();
    return ScheduleRow(
      timeRange: range,
      title: p.title,
      subtitle: desc.isEmpty ? null : desc,
      isActive: false,
      reminderProgramId: id.isEmpty ? null : id,
      reminderProgramStartUtc: id.isEmpty ? null : p.start,
      reminderProgramStopUtc: id.isEmpty ? null : p.stop,
      isNotificationScheduled: p.isScheduled,
    );
  }
}

String _initials(String title) {
  final t = title.trim();
  if (t.isEmpty) return '?';
  if (t.length >= 2) return t.substring(0, 2).toUpperCase();
  return t.toUpperCase();
}

// —— Screen —————————————————————————————————————————————————————————————————

class ChannelScheduleScreen extends StatefulWidget {
  const ChannelScheduleScreen({super.key});

  @override
  State<ChannelScheduleScreen> createState() => _ChannelScheduleScreenState();
}

class _ChannelScheduleScreenState extends State<ChannelScheduleScreen> {
  String? _controllerTag;

  @override
  void dispose() {
    final tag = _controllerTag;
    if (tag != null) {
      Get.delete<ChannelScheduleController>(tag: tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final raw = Get.arguments;
    if (raw is! IptvChannel) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('Missing channel')),
      );
    }
    final ch = raw;
    final tag = 'sch_${ch.favoriteKey.hashCode}_${ch.hashCode}';
    _controllerTag = tag;
    return GetBuilder<ChannelScheduleController>(
      tag: tag,
      init: ChannelScheduleController(ch),
      global: false,
      builder: (c) => _ScheduleBody(channel: ch, c: c),
    );
  }
}

class _ScheduleBody extends StatefulWidget {
  const _ScheduleBody({required this.channel, required this.c});

  final IptvChannel channel;
  final ChannelScheduleController c;

  @override
  State<_ScheduleBody> createState() => _ScheduleBodyState();
}

class _ScheduleBodyState extends State<_ScheduleBody> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Attach scroll listener to controller for pagination
    widget.c.attachScrollController(_scrollController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IptvChannel get channel => widget.channel;
  ChannelScheduleController get c => widget.c;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.channelScheduleScaffold,
      body: SafeArea(
        child: Column(
          children: [
            8.verticalSpace,
            _header(context),
            16.verticalSpace,
            Expanded(
              child: c.loading
                  ? const Center(child: CircularProgressIndicator())
                  : c.error != null
                      ? _errorBody(c)
                      : RefreshIndicator(
                          onRefresh: c.loadGuides,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _channelCard(context, c),
                                24.verticalSpace,
                                _dateRow(context, c),
                                24.verticalSpace,
                                if (c.currentRow == null &&
                                    c.upcomingItems.isEmpty)
                                  _emptyMessage(c)
                                else ...[
                                  if (c.currentRow != null) ...[
                                    _nowSectionHeader(),
                                    _activeCard(c.currentRow!),
                                    20.verticalSpace,
                                  ],
                                  if (c.upcomingItems.isNotEmpty) ...[
                                    ...c.upcomingItems
                                        .map((item) => _timelineEntry(item)),
                                    if (c.hasMoreGuide) _loadMoreFooter(c),
                                  ],
                                ],
                                14.verticalSpace,
                                const StackedAdFooter(),
                                16.verticalSpace,
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.channelScheduleHeaderAccent,
            splashRadius: 16.r,
          ),
          CustomText(
            'Channel Schedule',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            fontFamily: AppStrings.interBold,
            color: AppColors.textPrimaryLight,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _channelCard(BuildContext context, ChannelScheduleController c) {
    final ch = c.channel;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          _thumbnail(
            ch.logo.trim().isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: ch.logo.trim(),
                    fit: BoxFit.cover,
                    width: 48.r,
                    height: 48.r,
                    errorWidget: (_, __, ___) =>
                        _logoFallback(c.logoInitials),
                  )
                : _logoFallback(c.logoInitials),
          ),
          8.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  ch.titleWithLanguage,
                  maxLines: 1,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppStrings.interBold,
                  color: AppColors.textPrimaryLight,
                  height: 22.5 / 18,
                ),
                3.verticalSpace,
                Row(
                  children: [
                    Container(
                      width: 5.r,
                      height: 5.r,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    5.horizontalSpace,
                    CustomText(
                      'LIVE',
                      maxLines: 1,
                      fontSize: 11.sp,
                      fontFamily: AppStrings.interSemiBold,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                    8.horizontalSpace,
                    CustomText(
                      ch.feedIdLabel.isEmpty
                          ? 'Live Channel'
                          : 'Channel ${ch.feedIdLabel}',
                      maxLines: 1,
                      fontSize: 11.sp,
                      fontFamily: AppStrings.interMedium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondaryLight,
                      height: 16.5 / 11,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 10.horizontalSpace,
          // GestureDetector(
          //   onTap: () => _onWatchNowTap(context),
          //   child: Container(
          //     height: 36.h,
          //     constraints: BoxConstraints(minWidth: 117.31.w),
          //     padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          //     decoration: BoxDecoration(
          //       gradient:
          //           const LinearGradient(colors: AppColors.primaryGradient),
          //       borderRadius: BorderRadius.circular(9999.r),
          //       boxShadow: [
          //         BoxShadow(
          //           color: AppColors.black.withValues(alpha: 0.05),
          //           offset: const Offset(0, 1),
          //           blurRadius: 2,
          //         ),
          //       ],
          //     ),
          //     alignment: Alignment.center,
          //     child: CustomText(
          //       'Watch Now',
          //       maxLines: 1,
          //       fontSize: 14.sp,
          //       color: AppColors.white,
          //       fontFamily: AppStrings.interBold,
          //       fontWeight: FontWeight.w600,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _thumbnail(Widget child) {
    return Container(
      width: 48.r,
      height: 48.r,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.channelScheduleThumbnailFill,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.borderLight.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _logoFallback(String initials) {
    return CustomText(
      initials,
      maxLines: 1,
      fontSize: 9.sp,
      fontWeight: FontWeight.w800,
      fontFamily: AppStrings.interExtraBold,
      color: AppColors.textSecondaryLight,
    );
  }

  Widget _dateRow(BuildContext context, ChannelScheduleController c) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pickScheduleDate(context, c),
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomText(
                c.dateLabel,
                maxLines: 1,
                fontSize: 14.sp,
                fontFamily: AppStrings.interBold,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 20.sp,
                color: AppColors.textSecondaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickScheduleDate(
    BuildContext context,
    ChannelScheduleController c,
  ) async {
    final first = ChannelScheduleController.schedulePickerFirst;
    final last = ChannelScheduleController.schedulePickerLast;
    var initial = DateTime(
      c.selectedScheduleDay.year,
      c.selectedScheduleDay.month,
      c.selectedScheduleDay.day,
    );
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null || !context.mounted) return;
    c.setSelectedScheduleDay(picked);
  }

  Widget _emptyMessage(ChannelScheduleController c) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Center(
        child: CustomText(
          c.guideChannelId.isEmpty
              ? 'Schedule is available for channels from the catalog.'
              : 'No programs in the guide for this channel.',
          textAlign: TextAlign.center,
          fontSize: 14.sp,
          fontFamily: AppStrings.interMedium,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondaryLight,
          maxLines: 4,
        ),
      ),
    );
  }

  Widget _errorBody(ChannelScheduleController c) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: 48.r,
          color: AppColors.textSecondaryLight,
        ),
        16.verticalSpace,
        CustomText(
          'Couldn\'t load the schedule',
          textAlign: TextAlign.center,
          fontSize: 16.sp,
          fontFamily: AppStrings.interBold,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
          maxLines: 2,
        ),
        8.verticalSpace,
        CustomText(
          c.error!,
          textAlign: TextAlign.center,
          fontSize: 12.sp,
          fontFamily: AppStrings.interRegular,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryLight,
          maxLines: 6,
        ),
        24.verticalSpace,
        Center(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => c.loadGuides(),
            child: CustomText(
              'Try again',
              maxLines: 1,
              fontSize: 14.sp,
              fontFamily: AppStrings.interBold,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _nowSectionHeader() {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: CustomText(
        'NOW',
        maxLines: 1,
        fontSize: 13.sp,
        fontFamily: AppStrings.interBold,
        fontWeight: FontWeight.w700,
        color: AppColors.linkBlue,
      ),
    );
  }

  Widget _dayPartHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h, bottom: 6.h),
      child: CustomText(
        title,
        maxLines: 1,
        fontSize: 13.sp,
        fontFamily: AppStrings.interBold,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _timelineEntry(ScheduleTimelineItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.sectionTitle != null) _dayPartHeader(item.sectionTitle!),
        _scheduleRow(item.row),
      ],
    );
  }

  Widget _loadMoreFooter(ChannelScheduleController c) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: c.loadingMore
            ? Column(
                children: [
                  SizedBox(
                    height: 32.h,
                    width: 32.r,
                    child: const CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  8.verticalSpace,
                  CustomText(
                    'Loading more programs...',
                    maxLines: 1,
                    fontSize: 12.sp,
                    fontFamily: AppStrings.interMedium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                  ),
                ],
              )
            : FilledButton.tonal(
                onPressed: (c.loading || c.loadingMore) ? null : () {
                  debugPrint('Load more button pressed');
                  c.loadMoreGuides();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.channelScheduleScaffold,
                  foregroundColor: AppColors.channelScheduleHeaderAccent,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    side: BorderSide(
                      color: AppColors.channelScheduleHeaderAccent,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.expand_more_rounded,
                      size: 18.sp,
                      color: AppColors.channelScheduleHeaderAccent,
                    ),
                    6.horizontalSpace,
                    CustomText(
                      'Load more programs',
                      maxLines: 1,
                      fontSize: 14.sp,
                      fontFamily: AppStrings.interSemiBold,
                      fontWeight: FontWeight.w600,
                      color: AppColors.channelScheduleHeaderAccent,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _scheduleRow(ScheduleRow row) => _inactiveRow(row);

  Widget _activeCard(ScheduleRow item) {
    final progress = (item.progress ?? 0).clamp(0.0, 1.0);
    final showProgress = item.progress != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: AppColors.linkBlue,
              child: SizedBox(width: 4.w),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.white,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: CustomText(
                              item.timeRange,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              fontSize: 11.sp,
                              fontFamily: AppStrings.interBold,
                              fontWeight: FontWeight.w700,
                              color: AppColors.linkBlue,
                              height: 16.5 / 11,
                              letterSpacing: -0.28,
                            ),
                          ),
                          8.horizontalSpace,
                          Container(
                            padding: EdgeInsets.fromLTRB(8.w, 2.h, 8.w, 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.liveBadgeBackground,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: CustomText(
                              'NOW',
                              maxLines: 1,
                              fontSize: 10.sp,
                              fontFamily: AppStrings.interBold,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                              height: 15 / 10,
                            ),
                          ),
                        ],
                      ),
                      8.verticalSpace,
                      CustomText(
                        item.title,
                        maxLines: 2,
                        fontSize: 16.sp,
                        fontFamily: AppStrings.interBold,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                        height: 24 / 16,
                      ),
                      if (item.subtitle != null) ...[
                        4.verticalSpace,
                        CustomText(
                          item.subtitle!,
                          maxLines: 2,
                          fontSize: 12.sp,
                          fontFamily: AppStrings.interRegular,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondaryLight,
                          height: 16 / 12,
                        ),
                      ],
                      if (showProgress) ...[
                        10.verticalSpace,
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2.r),
                          child: SizedBox(
                            height: 4.h,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                const ColoredBox(
                                  color: AppColors.channelScheduleProgressTrack,
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: progress,
                                    heightFactor: 1,
                                    child: const ColoredBox(
                                      color: AppColors.linkBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        6.verticalSpace,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (item.elapsedLabel != null)
                              CustomText(
                                item.elapsedLabel!,
                                maxLines: 1,
                                fontSize: 10.sp,
                                fontFamily: AppStrings.interRegular,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondaryLight,
                                height: 15 / 10,
                              )
                            else
                              const SizedBox.shrink(),
                            if (item.leftLabel != null)
                              CustomText(
                                item.leftLabel!,
                                maxLines: 1,
                                textAlign: TextAlign.end,
                                fontSize: 10.sp,
                                fontFamily: AppStrings.interRegular,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondaryLight,
                                height: 15 / 10,
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inactiveRow(ScheduleRow item) {
    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.inputFillLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.all(16.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  item.timeRange,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 11.sp,
                  fontFamily: AppStrings.interMedium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight,
                 
                  letterSpacing: 0,
                ),
                4.verticalSpace,
                CustomText(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 17.sp,
                  fontFamily: AppStrings.interSemiBold,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                 
                  letterSpacing: 0,
                ),
                // if (item.subtitle != null) ...[
                //   4.verticalSpace,
                //   CustomText(
                //     item.subtitle!,
                //     maxLines: 1,
                //     overflow: TextOverflow.ellipsis,
                //     fontSize: 11.sp,
                //     fontFamily: AppStrings.interRegular,
                //     fontWeight: FontWeight.w400,
                //     color:
                //         AppColors.textSecondaryLight.withValues(alpha: 0.85),
                //     height: 16.5 / 11,
                //   ),
                // ],
              ],
            ),
          ),
          8.horizontalSpace,
          _scheduleReminderBell(c, item),
        ],
      ),
    );
  }
}

Widget _scheduleReminderBell(ChannelScheduleController c, ScheduleRow item) {
  if (!c.showsReminderBell(item)) {
    return SizedBox(width: 25.w);
  }

  final program = c.programForReminder(item)!;
  final on = c.isReminderScheduled(item);
  final busy =
      c.notificationTogglingKey == c.notificationKeyFor(program.programStartTime);

  return InkWell(
    onTap: busy ? null : () => c.toggleProgramNotification(item),
    borderRadius: BorderRadius.circular(999),
    child: Padding(
      padding: EdgeInsets.all(4.r),
      child: busy
          ? SizedBox(
              width: 22.sp,
              height: 22.sp,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.channelScheduleHeaderAccent,
              ),
            )
          : Icon(
              on ? Icons.notifications_active : Icons.notifications_none_outlined,
              size: 25.sp,
              color: on
                  ? AppColors.channelScheduleHeaderAccent
                  : AppColors.textSecondaryLight,
            ),
    ),
  );
}
