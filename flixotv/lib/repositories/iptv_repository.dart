import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iptv_demo/constant/app_urls.dart';
import 'package:iptv_demo/model/channel_guide_model.dart';
import 'package:iptv_demo/model/channel_program.dart';
import 'package:iptv_demo/services/api_service.dart';

/// IPTV list / stream HTTP calls. Controllers build query URIs where needed.
class IptvRepository {
  IptvRepository(this._api);

  final ApiService _api;

  Future<http.Response> fetchCategories({
    required String countryCode,
    String? language,
    Map<String, String>? headers,
  }) {
    final queryParams = <String, String>{
      'country': countryCode.toUpperCase(),
    };
    if (language != null && language.isNotEmpty) {
      queryParams['language'] = language;
    }
    final uri =
        Uri.parse(AppUrls.category).replace(queryParameters: queryParams);
    return _api.get(
      uri,
      headers: headers,
      debugTag: 'Categories API',
    );
  }

  Future<http.Response> fetchCountries() {
    return _api.get(
      Uri.parse(AppUrls.countriesList),
      debugTag: 'Countries API',
    );
  }

  Future<http.Response> fetchLanguages({
    required String countryCode,
  }) {
    final uri = Uri.parse(AppUrls.languagesList).replace(
      queryParameters: <String, String>{
        'country_code': countryCode.toUpperCase(),
        'is_active': 'true',
      },
    );
    return _api.get(
      uri,
      debugTag: 'Languages API',
    );
  }

  Future<http.Response> fetchChannels(Uri uri, {required String debugTag}) {
    return _api.get(uri, debugTag: debugTag);
  }

  Future<http.Response> fetchStreamForChannel(String channelId) {
    return _api.get(
      Uri.parse('${AppUrls.streamsBase}$channelId'),
      debugTag: 'Streams API',
    );
  }

  Future<http.Response> fetchChannelInfoForChannel(String channelId) {
    return _api.get(
      Uri.parse('${AppUrls.channelInfoBase}$channelId'),
      debugTag: 'Channel Info API',
    );
  }

  /// `GET /guides/{channelId}/{channelDbId}` — optional `date=YYYY-MM-DD`, `limit`.
  Future<ChannelGuideData> fetchChannelGuides(
    String channelId,
    String channelDbId, {
    required int limit,
    String? date,
    Map<String, String>? headers,
  }) async {
    final query = <String, String>{'limit': limit.toString()};
    if (date != null && date.isNotEmpty) {
      query['date'] = date;
    }
    final uri = Uri.parse(AppUrls.channelGuides(channelId, channelDbId))
        .replace(queryParameters: query);
    final response = await _api.get(
      uri,
      headers: headers,
      debugTag: 'Channel Guides API',
    );

    if (response.statusCode != 200 || response.body.isEmpty) {
      throw Exception(
        _extractApiMessage(response.body, 'Could not load schedule'),
      );
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      throw Exception(
        _extractApiMessage(response.body, 'Could not load schedule'),
      );
    }

    final raw = decoded['data'];
    if (raw is Map<String, dynamic>) {
      return ChannelGuideData.fromJson(raw);
    }
    if (raw is Map) {
      return ChannelGuideData.fromJson(Map<String, dynamic>.from(raw));
    }
    return const ChannelGuideData(upcoming: []);
  }

  static String _extractApiMessage(String body, String fallback) {
    try {
      final decoded = json.decode(body) as Map<String, dynamic>;
      final msg = decoded['message'] as String?;
      if (msg != null && msg.trim().isNotEmpty) return msg.trim();
    } catch (_) {}
    return fallback;
  }

  Future<http.Response> fetchChannelPrograms(String channelDbId) {
    return _api.get(
      Uri.parse('${AppUrls.channelProgramsBase}$channelDbId'),
      debugTag: 'Channel Programs API',
    );
  }

  static List<ChannelProgram> parseProgramsResponse(String body) {
    try {
      final decoded = json.decode(body) as Map<String, dynamic>;
      if (decoded['success'] != true) return const [];

      final raw = decoded['data'];
      final List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map) {
        list = raw['programs'] as List<dynamic>? ??
            raw['schedule'] as List<dynamic>? ??
            raw['items'] as List<dynamic>? ??
            <dynamic>[];
      } else {
        return const [];
      }

      return list
          .map((e) => ChannelProgram.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((p) => p.isValid)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
