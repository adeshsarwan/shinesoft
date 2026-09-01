import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:iptv_demo/model/channel_program.dart';
import 'package:iptv_demo/repositories/notification_repository.dart';
import 'package:iptv_demo/services/auth_service.dart';

class NotificationService extends GetxService {
  NotificationRepository get _repo => Get.find<NotificationRepository>();
  AuthService get _auth => Get.find<AuthService>();

  Map<String, String> _authHeaders() => {
        'Authorization': 'Bearer ${_auth.accessToken.value}',
      };

  Future<Map<String, String>?> _authorizedHeaders() async {
    if (!_auth.isLoggedIn.value || _auth.accessToken.value.isEmpty) {
      return null;
    }
    return _authHeaders();
  }

  Future<http.Response?> _withAuthRetry(
    Future<http.Response> Function(Map<String, String> headers) call,
  ) async {
    var headers = await _authorizedHeaders();
    if (headers == null) return null;

    var response = await call(headers);
    if (response.statusCode == 401 && _auth.refreshToken.value.isNotEmpty) {
      if (await _auth.refreshSession()) {
        headers = await _authorizedHeaders();
        if (headers == null) return null;
        response = await call(headers);
      }
    }
    return response;
  }

  /// Schedules a push notification for a program. Returns `(success, message)`.
  Future<(bool, String)> scheduleProgramNotification({
    required ChannelProgram program,
    required String channelId,
    required String channelName,
  }) async {
    if (!program.isValid) {
      return (false, 'Invalid program data');
    }
    if (channelId.isEmpty) {
      return (false, 'Channel id is required');
    }

    try {
      final response = await _withAuthRetry(
        (headers) => _repo.scheduleNotification(
          headers: headers,
          showId: program.showId,
          showTitle: program.showTitle,
          channelId: channelId,
          channelName: channelName,
          programStartTime: program.programStartTime,
          programEndTime: program.programEndTime,
        ),
      );

      if (response == null) {
        return (false, 'Please sign in to schedule notifications');
      }

      return _parseResult(
        response,
        successFallback: 'Notification scheduled',
        failureFallback: 'Could not schedule notification',
      );
    } catch (e) {
      debugPrint('[Notifications] schedule error: $e');
      return (false, 'Network error. Please try again.');
    }
  }

  /// Cancels a scheduled program notification.
  Future<(bool, String)> cancelProgramNotification({
    required String channelId,
    required String programStartTime,
  }) async {
    if (channelId.isEmpty || programStartTime.isEmpty) {
      return (false, 'Invalid schedule data');
    }

    try {
      final response = await _withAuthRetry(
        (headers) => _repo.cancelSchedule(
          headers: headers,
          channelId: channelId,
          programStartTime: programStartTime,
        ),
      );

      if (response == null) {
        return (false, 'Please sign in to manage notifications');
      }

      return _parseResult(
        response,
        successFallback: 'Notification cancelled',
        failureFallback: 'Could not cancel notification',
      );
    } catch (e) {
      debugPrint('[Notifications] cancel error: $e');
      return (false, 'Network error. Please try again.');
    }
  }

  /// Returns whether a notification is scheduled for this program.
  Future<(bool isScheduled, String error)> isProgramNotificationScheduled({
    required String channelId,
    required String programStartTime,
  }) async {
    if (channelId.isEmpty || programStartTime.isEmpty) {
      return (false, 'Invalid schedule data');
    }

    try {
      final response = await _withAuthRetry(
        (headers) => _repo.checkSchedule(
          headers: headers,
          channelId: channelId,
          programStartTime: programStartTime,
        ),
      );

      if (response == null) {
        return (false, 'Please sign in');
      }

      if (response.statusCode != 200 || response.body.isEmpty) {
        return (false, _extractMessage(response.body, 'Could not check schedule'));
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        return (false, _extractMessage(response.body, 'Could not check schedule'));
      }

      final data = decoded['data'];
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final scheduled = map['isScheduled'] ??
            map['scheduled'] ??
            map['hasSchedule'] ??
            map['is_scheduled'];
        if (scheduled is bool) return (scheduled, '');
        if (scheduled is num) return (scheduled != 0, '');
        if (scheduled is String) {
          final s = scheduled.toLowerCase();
          return (s == 'true' || s == '1' || s == 'yes', '');
        }
      }

      if (decoded['isScheduled'] is bool) {
        return (decoded['isScheduled'] as bool, '');
      }

      return (false, '');
    } catch (e) {
      debugPrint('[Notifications] check error: $e');
      return (false, 'Network error');
    }
  }

  (bool, String) _parseResult(
    http.Response response, {
    required String successFallback,
    required String failureFallback,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return (false, _extractMessage(response.body, failureFallback));
    }

    if (response.body.isEmpty) {
      return (true, successFallback);
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == false) {
        return (false, _extractMessage(response.body, failureFallback));
      }
      return (true, _extractMessage(response.body, successFallback));
    } catch (_) {
      return (true, successFallback);
    }
  }

  String _extractMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final msg = decoded['message'] as String?;
      if (msg != null && msg.trim().isNotEmpty) return msg.trim();
    } catch (_) {}
    return fallback;
  }
}
