// Shared EPG "now playing" progress math (channel schedule + home cards).

/// Normalizes guide/program instants for comparisons (stored as UTC).
///
/// - ISO with `Z` or offset → UTC instant (same as [DateTime.parse] + [DateTime.toUtc]).
/// - Naive ISO → device-local wall clock (same as mobile [DateTime.parse]), then UTC.
DateTime parseGuideDateTime(String raw) {
  final s = raw.trim();
  if (s.isEmpty) {
    return DateTime.now().toUtc();
  }
  final parsed = DateTime.parse(s);
  if (parsed.isUtc) {
    return parsed;
  }
  if (s.endsWith('Z') ||
      RegExp(r'[+-]\d{2}:\d{2}$|[+-]\d{4}$').hasMatch(s)) {
    return parsed.toUtc();
  }
  // Naive — local wall clock on this device (matches mobile channel schedule).
  return parsed.toUtc();
}

/// Local wall clock for labels (12h AM/PM), progress, and day buckets.
DateTime guideDisplayLocal(DateTime value) => value.toLocal();

/// `date` query for `GET /guides/...` using the device local calendar day.
String guidesApiDateParamForLocalDay(DateTime localDay) {
  final d = DateTime(localDay.year, localDay.month, localDay.day);
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Same range label as mobile channel schedule (`7:00 PM — 11:01 PM`).
String formatGuideTimeRange(DateTime startUtc, DateTime stopUtc) {
  final startL = guideDisplayLocal(startUtc);
  final stopL = guideDisplayLocal(stopUtc);
  return '${formatScheduleClockLocal(startL)} — ${formatScheduleClockLocal(stopL)}';
}

String formatShortDurationForGuide(Duration d) {
  if (d.isNegative) return '0m';
  final totalMin = d.inMinutes;
  if (totalMin < 60) return '${totalMin}m';
  final h = totalMin ~/ 60;
  final m = totalMin % 60;
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

String formatScheduleClockLocal(DateTime local) {
  var hour = local.hour % 12;
  if (hour == 0) hour = 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $suffix';
}

class GuideLiveProgress {
  const GuideLiveProgress({
    required this.progress,
    required this.elapsedLabel,
    required this.leftLabel,
  });

  final double progress;
  final String elapsedLabel;
  final String leftLabel;

  static GuideLiveProgress compute(DateTime startUtc, DateTime stopUtc) {
    final now = DateTime.now().toUtc();
    final start = startUtc.toUtc();
    final stop = stopUtc.toUtc();
    final total = stop.difference(start);
    if (now.isBefore(start)) {
      return GuideLiveProgress(
        progress: 0,
        elapsedLabel: '0m elapsed',
        leftLabel: '${formatShortDurationForGuide(total)} left',
      );
    }
    if (!now.isBefore(stop)) {
      return GuideLiveProgress(
        progress: 1,
        elapsedLabel: '${formatShortDurationForGuide(total)} elapsed',
        leftLabel: '0m left',
      );
    }
    final msTotal = total.inMilliseconds;
    final p = msTotal <= 0
        ? 0.0
        : (now.difference(start).inMilliseconds / msTotal).clamp(0.0, 1.0);
    return GuideLiveProgress(
      progress: p,
      elapsedLabel:
          '${formatShortDurationForGuide(now.difference(start))} elapsed',
      leftLabel: '${formatShortDurationForGuide(stop.difference(now))} left',
    );
  }
}
