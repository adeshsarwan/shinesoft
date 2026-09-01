import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iptv_demo/constant/app_urls.dart';
import 'package:iptv_demo/services/api_service.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiService _api;

  Future<http.Response> scheduleNotification({
    required Map<String, String> headers,
    required String showId,
    required String showTitle,
    required String channelId,
    required String channelName,
    required String programStartTime,
    required String programEndTime,
  }) {
    return _api.post(
      Uri.parse(AppUrls.notificationsSchedule),
      headers: headers,
      body: jsonEncode({
        'showId': showId,
        'showTitle': showTitle,
        'channelId': channelId,
        'channelName': channelName,
        'programStartTime': programStartTime,
        'programEndTime': programEndTime,
      }),
      debugTag: 'Notifications / schedule',
    );
  }

  Future<http.Response> cancelSchedule({
    required Map<String, String> headers,
    required String channelId,
    required String programStartTime,
  }) {
    return _api.delete(
      Uri.parse(AppUrls.notificationsCancelSchedule),
      headers: headers,
      body: jsonEncode({
        'channelId': channelId,
        'programStartTime': programStartTime,
      }),
      debugTag: 'Notifications / cancel schedule',
    );
  }

  Future<http.Response> checkSchedule({
    required Map<String, String> headers,
    required String channelId,
    required String programStartTime,
  }) {
    return _api.post(
      Uri.parse(AppUrls.notificationsCheckSchedule),
      headers: headers,
      body: jsonEncode({
        'channelId': channelId,
        'programStartTime': programStartTime,
      }),
      debugTag: 'Notifications / check schedule',
    );
  }
}
