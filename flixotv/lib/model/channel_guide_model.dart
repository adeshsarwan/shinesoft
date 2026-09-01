import 'package:iptv_demo/utils/guide_live_progress.dart';

/// Response body from `GET /api/v1/guides/{channelId}/{channelDbId}` (`limit`, optional `date=YYYY-MM-DD`).
class ChannelGuideData {
  const ChannelGuideData({
    this.current,
    required this.upcoming,
  });

  final ChannelGuideProgram? current;
  final List<ChannelGuideProgram> upcoming;

  factory ChannelGuideData.fromJson(Map<String, dynamic> json) {
    final rawCurrent = json['current'];
    ChannelGuideProgram? current;
    if (rawCurrent is Map<String, dynamic>) {
      current = ChannelGuideProgram.fromJson(rawCurrent);
    }
    final rawUp = json['upcoming'];
    final upcoming = <ChannelGuideProgram>[];
    if (rawUp is List<dynamic>) {
      for (final e in rawUp) {
        if (e is Map<String, dynamic>) {
          upcoming.add(ChannelGuideProgram.fromJson(e));
        }
      }
    }
    return ChannelGuideData(current: current, upcoming: upcoming);
  }
}

class ChannelGuideProgram {
  const ChannelGuideProgram({
    required this.id,
    required this.channel,
    required this.title,
    required this.description,
    required this.category,
    required this.start,
    required this.stop,
    this.isScheduled = false,
  });

  final String id;
  final String channel;
  final String title;
  final String description;
  final String category;
  final DateTime start;
  final DateTime stop;

  /// From guides API — whether a push reminder is already scheduled.
  final bool isScheduled;

  factory ChannelGuideProgram.fromJson(Map<String, dynamic> json) {
    return ChannelGuideProgram(
      id: json['_id']?.toString() ?? '',
      channel: json['channel']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      start: _parseGuideInstant(json['start']),
      stop: _parseGuideInstant(json['stop']),
      isScheduled: _parseBool(json['isScheduled']),
    );
  }

  static DateTime _parseGuideInstant(dynamic raw) {
    if (raw == null) return DateTime.now().toUtc();
    if (raw is DateTime) return raw.toUtc();
    if (raw is num) {
      final ms = raw.toInt();
      if (ms > 1e12) {
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      }
      return DateTime.fromMillisecondsSinceEpoch(ms * 1000, isUtc: true);
    }
    return parseGuideDateTime(raw.toString());
  }

  static bool _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }
}

/// Cached `/guides/{id}` row for home cards (now playing strip).
class HomeGuideEntry {
  const HomeGuideEntry({required this.loading, this.current});

  final bool loading;
  final ChannelGuideProgram? current;
}
