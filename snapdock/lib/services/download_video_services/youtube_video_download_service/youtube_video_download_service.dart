import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:videodownloader/apis/api_endpoints.dart';

class YouTubeVideoDownloadService {

  /// Downloads YouTube video information
  /// Returns a map with video URLs similar to InstagramDownloadResponse structure
  Future<Map<String, dynamic>?> downloadYouTubeVideo(String youtubeUrl) async {
    try {
      print("YouTube API Call Started for URL: $youtubeUrl");

      final requestBody = {
        "url": "/media/parse",
        "data": {
          "origin": "cache",
          "link": youtubeUrl,
        },
        "token": "",
      };

      final response = await http.post(
        Uri.parse(ApiEndpoints.youtubeDownload),
        headers: {
          'accept': '*/*',
          'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8,gu;q=0.7',
          'content-type': 'application/json',
          'origin': 'https://vidssave.com',
          'priority': 'u=1, i',
          'referer': 'https://vidssave.com/yt',
          'sec-ch-ua': '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
          'sec-ch-ua-mobile': '?0',
          'sec-ch-ua-platform': '"Linux"',
          'sec-fetch-dest': 'empty',
          'sec-fetch-mode': 'cors',
          'sec-fetch-site': 'same-origin',
          'user-agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
        },
        body: jsonEncode(requestBody),
      );

      print("YouTube API Status Code: ${response.statusCode}");
      print("YouTube API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          print("Parsed YouTube JSON: $jsonData");

          // Check if status is success
          if (jsonData is Map<String, dynamic> && jsonData['status'] == 1) {
            final data = jsonData['data'] as Map<String, dynamic>?;
            
            if (data == null) {
              print("No data field in response");
              return null;
            }

            // Extract thumbnail
            String? thumbnailUrl = data['thumbnail'] as String?;
            print("📸 Thumbnail URL: $thumbnailUrl");

            // Extract resources array
            final resources = data['resources'] as List<dynamic>?;
            if (resources == null || resources.isEmpty) {
              print("No resources found in response");
              return null;
            }

            // Filter video resources and extract download URLs
            List<Map<String, dynamic>> videoResources = [];
            
            for (var resource in resources) {
              if (resource is Map<String, dynamic>) {
                final type = resource['type'] as String?;
                if (type == 'video') {
                  final downloadUrl = resource['download_url'] as String?;
                  final quality = resource['quality'] as String?;
                  final format = resource['format'] as String?;
                  
                  if (downloadUrl != null && downloadUrl.isNotEmpty) {
                    final size = resource['size'] as int?;
                    videoResources.add({
                      'url': downloadUrl,
                      'quality': quality ?? '',
                      'format': format ?? '',
                      'size': size ?? 0,
                    });
                    print("✅ Found video: Quality=$quality, Format=$format, Size=$size, URL=$downloadUrl");
                  }
                }
              }
            }

            if (videoResources.isEmpty) {
              print("No video resources found in response");
              return null;
            }

            // Sort by quality (prefer higher quality)
            // Quality order: 2160P > 1440P > 1080P > 720P > 480P > 360P > 240P > 144P
            videoResources.sort((a, b) {
              final qualityA = a['quality'] as String;
              final qualityB = b['quality'] as String;
              
              // Extract numeric value from quality string (e.g., "1080P" -> 1080)
              int getQualityValue(String quality) {
                final match = RegExp(r'(\d+)').firstMatch(quality);
                if (match != null) {
                  return int.parse(match.group(1)!);
                }
                // For non-numeric qualities, assign lower priority
                if (quality.contains('LOW')) return 0;
                return -1;
              }
              
              return getQualityValue(qualityB).compareTo(getQualityValue(qualityA));
            });

            // Extract just the URLs in sorted order
            List<String> videoUrls = videoResources
                .map((resource) => resource['url'] as String)
                .toList();

            print("📦 Extracted ${videoUrls.length} video URLs (sorted by quality)");
            for (int i = 0; i < videoUrls.length; i++) {
              print("  ${i + 1}. ${videoResources[i]['quality']}: ${videoUrls[i]}");
            }

            // Return in a format compatible with InstagramDownloadResponse
            // Also include quality information for selection dialog
            return {
              's3Files': videoUrls,
              'videoResources': videoResources, // Include quality info for selection
              'thumbnail': thumbnailUrl ?? '',
              'message': 'success',
              'shortcode': '',
            };
          } else {
            print("API returned status != 1 or invalid response structure");
            return null;
          }
        } catch (e, stackTrace) {
          print("Error parsing YouTube JSON response: $e");
          print("Stack trace: $stackTrace");
          return null;
        }
      } else {
        print("YouTube API returned non-200 status code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error calling YouTube API: $e");
      return null;
    }
  }
}

