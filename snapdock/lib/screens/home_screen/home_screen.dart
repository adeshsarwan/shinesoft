import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:media_store_plus/media_store_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:videodownloader/core/ads_services/banner_ads_service.dart';
import 'package:videodownloader/core/ads_services/interstitial_ads_service.dart';
import 'package:videodownloader/core/ads_services/native_ads_service.dart';
import 'package:videodownloader/core/ads_services/reward_ads_service.dart';
import 'package:videodownloader/core/state/premium_state.dart';
import 'package:videodownloader/l10n/app_localizations.dart';
import 'package:videodownloader/screens/downloads/downloaded_video_screen.dart';
import 'package:videodownloader/screens/downloads/whatsapp_status_saver_screen.dart';
import 'package:videodownloader/screens/instagram_login_screen/instagram_login_screen.dart';
import 'package:videodownloader/screens/profile/profile_screen/profile_screen.dart';
import 'package:videodownloader/screens/profile/subscription_screen/subscription_screen.dart';
import 'package:videodownloader/services/download_video_services/downloaded_video_store_service/downloaded_video_store_service.dart';
import 'package:videodownloader/services/models/instagram_download_model/instagram_download_model.dart';
import 'package:videodownloader/apis/api_endpoints.dart';
import 'package:videodownloader/services/download_video_services/youtube_video_download_service/youtube_video_download_service.dart';
import 'package:videodownloader/core/storage/local_database/database_helper.dart';

class HomePageScreen extends StatefulWidget {
  HomePageScreen({super.key});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen>
    with WidgetsBindingObserver {
  bool isHome = true;
  bool isLoading = false;
  InstagramDownloadResponse? instagramResponse;
  String thumnailImageURL = "";
  String inputUserURL = "";
  final TextEditingController _urlController = TextEditingController();

  String savedVideoPathLocalDB = "";
  String? savedVideoFileNameFromLocalDB = "";
  String? savedVideoFileName = "";

  bool isDownloaded = false;
  bool isTextFiledEmpty = false;
  double downloadProgress = 0.0;
  bool isDownloading = false;
  String? _lastProcessedClipboardUrl;

  // Ads variables
  final BannerAdsService _adService = BannerAdsService();
  final RewardAdsService _rewardAdService = RewardAdsService();
  final InterstitialAdService _interstitialAdService = InterstitialAdService();
  final NativeAdsService _nativeAdService = NativeAdsService();
  bool _isAdInitialized = false;
  bool _isBannerAdReady = false;
  BannerAd? _bannerAd;
  bool _isRewardAdShowing = false;
  bool _shouldShowInterstitialOnLink = false;
  bool _isMediumRectangleAdReady = false;

  // Variables to track download state during ad
  String? _videoUrlForDownload;
  String? _fileNameForDownload;

  // Add this single flag
  bool _ignoreClipboardCheck = false;

  // Snackbar control so we only show "completed" once per download
  bool _hasShownDownloadCompleteSnackbar = false;

  // YouTube quality selection (cached by URL so same video shows dialog without re-fetch)
  List<Map<String, dynamic>>? _youtubeVideoResources;
  String? _lastYoutubeUrlWithResources;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize ads only for non-premium users
    if (!PremiumState.isPremium.value) {
      _initializeAds();
      // Load interstitial ad on initialization
      _loadInterstitialAd();
    }

    // Clipboard auto-paste disabled: user pastes link manually in text field only.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Clipboard check on resume disabled: user pastes link manually only.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlController.dispose();
    _bannerAd?.dispose();
    _rewardAdService.dispose();
    _interstitialAdService.dispose();
    _nativeAdService.disposeAd();
    _bannerAd = null;
    super.dispose();
  }

  Future<void> _initializeAds() async {
    if (PremiumState.isPremium.value) return;
    try {
      await _adService.initializeMobileAds();

      // Load rewarded ad on initialization
      _rewardAdService.loadRewardedAd(
        onAdLoaded: () {
          print('Rewarded ad pre-loaded successfully');
        },
        onAdFailedToLoad: (error) {
          print('Failed to pre-load rewarded ad: $error');
          // Retry loading after 10 seconds if failed
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) _rewardAdService.loadRewardedAd();
          });
        },
      );

      setState(() {
        _isAdInitialized = true;
      });

      // Load banner ad after initialization
      _loadBannerAd();

      // Load medium rectangle ad after initialization
      _loadMediumRectangleAd();
    } catch (e) {
      print('Failed to initialize ads: $e');
    }
  }

  Future<void> _loadInterstitialAd() async {
    if (PremiumState.isPremium.value) return;
    _interstitialAdService.loadInterstitialAd(
      onAdLoaded: () {
        print('Interstitial ad loaded successfully');
      },
      onAdFailedToLoad: (error) {
        print('Failed to load interstitial ad: $error');
        // Retry after 30 seconds
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) _loadInterstitialAd();
        });
      },
      onAdDismissed: () {
        print('Interstitial ad dismissed, loading next one');
        // Load next interstitial ad
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _loadInterstitialAd();
        });
      },
    );
  }

  Future<void> _loadBannerAd() async {
    if (PremiumState.isPremium.value) return;
    if (!_isAdInitialized) return;

    // Reset local ready flag before requesting a fresh banner instance.
    if (mounted) {
      setState(() {
        _isBannerAdReady = false;
      });
    } else {
      _isBannerAdReady = false;
    }

    _bannerAd = await _adService.loadBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: () {
        if (!mounted) return;
        setState(() {
          _isBannerAdReady = true;
        });
      },
      onAdFailedToLoad: (error) {
        if (mounted) {
          setState(() {
            _isBannerAdReady = false;
          });
        } else {
          _isBannerAdReady = false;
        }
        print('Banner ad failed to load: $error');

        // Retry loading the ad after 30 seconds
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) _loadBannerAd();
        });
      },
    );
  }

  Future<void> _loadMediumRectangleAd() async {
    if (!_isAdInitialized || PremiumState.isPremium.value) return;

    _nativeAdService.loadMediumRectangleAd(
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isMediumRectangleAdReady = true;
          });
        }
      },
      onAdFailedToLoad: (error) {
        if (mounted) {
          setState(() {
            _isMediumRectangleAdReady = false;
          });
        }
        print('Medium rectangle ad failed to load: $error');
      },
    );
  }

  // Show interstitial ad when user pastes a link
  void _showInterstitialAdOnLinkPaste() {
    if (PremiumState.isPremium.value) {
      return;
    }
    if (_interstitialAdService.isInterstitialAdReady) {
      print('Showing interstitial ad on link paste');
      _interstitialAdService.showInterstitialAd();
    } else {
      // Don't force-load and immediately show — this causes the ad to fire
      // multiple times in a loop alongside the rewarded ad. Just skip for now;
      // the pre-load in _loadInterstitialAd() will make it ready for next time.
      print('Interstitial ad not ready, skipping to avoid ad loop');
    }
  }

  // Show rewarded ad during download process
  Future<void> _showRewardedAdDuringDownload() async {
    if (PremiumState.isPremium.value) {
      // Premium users should download without watching ads
      _startBackgroundDownload();
      return;
    }
    if (_isRewardAdShowing) {
      print('Rewarded ad is already showing');
      return;
    }

    try {
      setState(() {
        _isRewardAdShowing = true;
      });

      // Start the download in background BEFORE showing the ad
      _startBackgroundDownload();

      // Then show the ad
      _rewardAdService.showRewardedAd(
        onAdDismissed: () {
          print('Rewarded ad dismissed');
          setState(() {
            _isRewardAdShowing = false;
          });
        },
        onUserEarnedReward: (reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
          // You can implement reward logic here if needed
          // For example, give extra features or remove ads for some time
        },
      );
    } catch (e) {
      print('Error showing rewarded ad: $e');
      setState(() {
        _isRewardAdShowing = false;
      });
    }
  }

  void downloadVideoFromInDevice() async {
    try {
      print("Checking video URL...");

      // Check if this is a YouTube video with quality selection
      if (_youtubeVideoResources != null &&
          _youtubeVideoResources!.isNotEmpty) {
        // Show quality selection dialog for YouTube
        _showYouTubeQualitySelectionDialog();
        return;
      }

      // For Instagram/Facebook, use existing logic
      String videoUrl =
          instagramResponse?.s3Files.firstWhere(
            (item) => item.toLowerCase().endsWith(".mp4"),
            orElse: () => "",
          ) ??
          "";

      print("Video URL: $videoUrl");
      if (videoUrl.isEmpty) {
        // Try to get first available URL if no .mp4 found
        if (instagramResponse?.s3Files.isNotEmpty == true) {
          videoUrl = instagramResponse!.s3Files.first;
        }
      }

      if (videoUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No video found to download!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Store video URL for background download
      _videoUrlForDownload = videoUrl;
      _fileNameForDownload = "video_${DateTime.now().millisecondsSinceEpoch}";

      // Show rewarded ad and start download in background
      _showRewardedAdDuringDownload();
    } catch (e) {
      print("Error preparing download: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error preparing download: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showYouTubeQualitySelectionDialog() {
    if (_youtubeVideoResources == null || _youtubeVideoResources!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video qualities available!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Select Video Quality',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: _youtubeVideoResources!.length,
                    itemBuilder: (context, index) {
                      final resource = _youtubeVideoResources![index];
                      final quality =
                          resource['quality'] as String? ?? 'Unknown';
                      final format = resource['format'] as String? ?? '';
                      final url = resource['url'] as String? ?? '';

                      // Format file size if available
                      String sizeText = '';
                      if (resource.containsKey('size') &&
                          resource['size'] != null) {
                        final sizeBytes = resource['size'] as int? ?? 0;
                        if (sizeBytes > 0) {
                          if (sizeBytes > 1024 * 1024) {
                            sizeText =
                                '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
                          } else {
                            sizeText =
                                '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
                          }
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _startYouTubeDownload(url, quality);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE1306C),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.download,
                                color: Color(0xFFE1306C),
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                quality,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFFE1306C),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                format,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (sizeText.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  sizeText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  isLoading = false;
                });
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startYouTubeDownload(String videoUrl, String quality) {
    try {
      print("Starting download with quality: $quality");
      print("Video URL: $videoUrl");

      if (videoUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid video URL!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Store video URL for background download
      _videoUrlForDownload = videoUrl;
      _fileNameForDownload =
          "youtube_${DateTime.now().millisecondsSinceEpoch}_$quality";

      // Keep _youtubeVideoResources so same URL can show dialog again without re-fetch

      // Show rewarded ad and start download in background
      _showRewardedAdDuringDownload();
    } catch (e) {
      print("Error starting YouTube download: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting download: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  // Separate method for background download process
  void _startBackgroundDownload() async {
    if (_videoUrlForDownload == null || _fileNameForDownload == null) {
      print("No video URL or file name available for download");
      return;
    }

    try {
      print("Starting background video download...");

      setState(() {
        isDownloading = true;
        downloadProgress = 0.0;
        _hasShownDownloadCompleteSnackbar = false;
      });

      var downloader = DownloadedVideoStoreService();
      String? filePath = await downloader.downloadVideoAsync(
        _videoUrlForDownload!,
        _fileNameForDownload!,
        onProgress: (received, total) {
          if (total > 0) {
            double progress = (received / total * 100).clamp(0, 100);
            setState(() {
              downloadProgress = progress;
            });
            print(
              "Video Download in progress...: ${progress.toStringAsFixed(0)}%",
            );

            // When progress reaches 100%, show success snackbar once
            if (progress >= 100 &&
                !_hasShownDownloadCompleteSnackbar &&
                mounted) {
              _hasShownDownloadCompleteSnackbar = true;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video downloaded successfully!'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
      );

      String? filePathTemp = await downloader.saveToDownload(
        _videoUrlForDownload!,
        _fileNameForDownload!,
      );
      print("path Video 222 :-${filePath}");
      print("filePathTemp :- ${filePathTemp}");

      if (filePath == null) {
        print("not getting path: ${filePath}");
        setState(() {
          isDownloading = false;
          isLoading = false;
          _isRewardAdShowing = false; // Hide ad overlay when download fails
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download failed! Please try again.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final controller = VideoPlayerController.file(File(filePath));
      await controller.initialize();
      print("New Path Downloaded to: $filePath");

      if (Platform.isAndroid) {
        await MediaStore.ensureInitialized();
        MediaStore.appFolder = "VideoDownloader";
        final mediaStore = MediaStore();
        await mediaStore.saveFile(
          tempFilePath: filePath,
          dirType: DirType.video,
          dirName: DirName.movies,
        );
        print("Saved to MediaStore. Original filePath: $filePath");
      }

      // Save the actual file path to database (filePath is where the video was downloaded)
      // This path is accessible and can be used to play the video
      // Ensure we're saving a clean string path, not any object
      if (filePath != null && filePath.isNotEmpty) {
        String cleanPath = filePath.trim();
        print("💾 Preparing to save to DB with path: $cleanPath");
        print("💾 Thumbnail URL at save time: $thumnailImageURL");
        await saveToLocalDB(cleanPath);
      } else {
        print("❌ Cannot save to DB: filePath is null or empty");
      }

      setState(() {
        isDownloading = false;
        isLoading = false;
        _isRewardAdShowing =
            false; // Hide "watch ad" overlay when download completes
      });

      // Clear the stored download data
      _videoUrlForDownload = null;
      _fileNameForDownload = null;
    } catch (e) {
      print("Download error: $e");
      setState(() {
        isDownloading = false;
        isLoading = false;
        downloadProgress = 0.0;
        _hasShownDownloadCompleteSnackbar = false;
        _isRewardAdShowing = false; // Hide ad overlay on error too
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Clear the stored download data
      _videoUrlForDownload = null;
      _fileNameForDownload = null;
    }
  }

  Future<void> saveToLocalDB(String videoPath) async {
    try {
      String? imageUrl = thumnailImageURL.toString().trim();
      print("💾 Saving to DB - videoPath: $videoPath");
      print("💾 Saving to DB - thumbnailImageURL: $imageUrl");

      // Validate video path (required)
      if (videoPath.isEmpty) {
        print("❌ Cannot save: videoPath is empty");
        return;
      }

      // Use empty string for imageUrl if not available (thumbnail is optional)
      if (imageUrl.isEmpty) {
        print("⚠️ Thumbnail URL is empty, saving with empty thumbnail");
        imageUrl = "";
      }

      // Save to database
      int id = await LocalDB.instance.insertDownload(imageUrl, videoPath);
      print("✅ Successfully saved to DB with ID: $id");
    } catch (e, stackTrace) {
      print("❌ Error saving to DB: $e");
      print("Stack trace: $stackTrace");
    }
  }

  void inputInstagramReeDownlodlLink(String reelsURl) async {
    if (_isRewardAdShowing) {
      print("Reward ad is showing, skipping new request");
      return;
    }

    if (Platform.isAndroid) {
      try {
        final android = await DeviceInfoPlugin().androidInfo;
        print(android.version.sdkInt);
        if (android.version.sdkInt >= 30) {
          print("Android 11 or higher - using app storage, no permission required");
          // On Android 11+ download goes to app dir then MediaStore; no storage permission needed
        } else {
          print("Below Android 11");
          askStoragePermission();
        }
      } catch (e) {
        // If device info is unavailable, fall back to requesting storage permission.
        print("Failed to read Android version: $e");
        askStoragePermission();
      }
    } else {
      print("Non-Android platform detected - skipping Android storage checks");
    }

    final trimmedUrl = reelsURl.trim();
    setState(() {
      isLoading = true;
      // Only clear YouTube resources when URL changed (reuse for same video)
      if (trimmedUrl != _lastYoutubeUrlWithResources) {
        _youtubeVideoResources = null;
        _lastYoutubeUrlWithResources = null;
      }
    });
    print("API Call Started...");
    print("URL being processed: $reelsURl");
    print("Is valid URL: ${isValidInstagramUrl(reelsURl)}");

    InstagramDownloadResponse? data;

    // For same YouTube URL, reuse cached quality list and show dialog without API call
    if (isValidYouTubeUrl(reelsURl) &&
        _youtubeVideoResources != null &&
        _youtubeVideoResources!.isNotEmpty &&
        _lastYoutubeUrlWithResources == trimmedUrl) {
      print("Same YouTube URL - reusing cached quality list");
      setState(() {
        isLoading = false;
      });
      downloadVideoFromInDevice();
      return;
    }

    // Check if it's a YouTube URL
    if (isValidYouTubeUrl(reelsURl)) {
      print("Detected YouTube URL, calling YouTube download service");
      data = await downloadYouTubeVideo(reelsURl);
    } else {
      print(
        "Detected Instagram/Facebook URL, calling Instagram download service",
      );
      data = await downloadInstagramReel("${reelsURl}");
    }

    if (data != null) {
      final responseData = data; // Store in local variable for null safety
      final isYouTube = isValidYouTubeUrl(reelsURl);

      setState(() {
        isLoading = false;
        instagramResponse = responseData;

        // For YouTube, thumbnail is already set in downloadYouTubeVideo method
        // For Instagram/Facebook, try to find thumbnail image in s3Files
        if (!isYouTube) {
          String thumbnailUrl = "";
          final imageExtensions = [".jpg", ".jpeg", ".png", ".webp"];
          for (String ext in imageExtensions) {
            try {
              thumbnailUrl =
                  instagramResponse?.s3Files.firstWhere(
                    (item) => item.toLowerCase().endsWith(ext),
                    orElse: () => "",
                  ) ??
                  "";
              if (thumbnailUrl.isNotEmpty) break;
            } catch (e) {
              // Continue to next extension
            }
          }

          if (thumbnailUrl.isNotEmpty) {
            thumnailImageURL = thumbnailUrl;
            print("📸 Thumbnail URL extracted: $thumbnailUrl");
          }
        } else {
          print("📸 Using YouTube thumbnail URL: $thumnailImageURL");
        }

        print("📦 All S3 Files: ${responseData.s3Files}");
      });
      downloadVideoFromInDevice();
      print("Download data received. S3 Files: ${responseData.s3Files}");
    } else {
      setState(() {
        isLoading = false;
        isDownloading = false;
        downloadProgress = 0.0;
      });
      print(
        "Failed to download - API returned null. Check API response above.",
      );
    }
  }

  Future<bool> requestVideoPermission() async {
    var status = await Permission.videos.request();
    if (status.isGranted) {
      return true;
    } else {
      print("Permission Denied");
      return false;
    }
  }

  Future<void> askStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.request();
      await Permission.videos.request();

      if (status.isGranted) {
        print("✔ Storage Granted");
      } else {
        print("❌ Permission Denied");
      }
    }
  }

  Future<void> checkAndroidVersion() async {
    if (!Platform.isAndroid) {
      print("checkAndroidVersion called on non-Android platform");
      return;
    }

    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;

    print("Android Version: ${android.version.release}");
    print("SDK Version: ${android.version.sdkInt}");
  }

  bool isValidInstagramUrl(String url) {
    // Check for Instagram URLs
    final instagramPattern =
        r'^(https?:\/\/)?'
        r'((www|m)\.)?'
        r'instagram\.com\/'
        r'(?:(reel|reels|p|tv|stories)\/)'
        r'([A-Za-z0-9._\-]+)'
        r'(\/)?'
        r'(\?.*)?$';
    final instagramRegex = RegExp(instagramPattern, caseSensitive: false);

    // Check for Facebook URLs
    final facebookPattern =
        r'^(https?:\/\/)?'
        r'((www|m|web)\.)?'
        r'(facebook\.com|fb\.com)\/'
        r'.*(videos|watch|share)'
        r'.*';
    final facebookRegex = RegExp(facebookPattern, caseSensitive: false);

    // Check for YouTube URLs
    final youtubePattern =
        r'^(https?:\/\/)?'
        r'((www|m)\.)?'
        r'(youtube\.com|youtu\.be)\/'
        r'(watch\?v=|shorts\/|embed\/|v\/|e\/|.*[?&]v=)?'
        r'([A-Za-z0-9._\-]{11})'
        r'.*$';
    final youtubeRegex = RegExp(youtubePattern, caseSensitive: false);

    String trimmedUrl = url.trim();
    return instagramRegex.hasMatch(trimmedUrl) ||
        facebookRegex.hasMatch(trimmedUrl) ||
        youtubeRegex.hasMatch(trimmedUrl);
  }

  bool isValidYouTubeUrl(String url) {
    final youtubePattern =
        r'^(https?:\/\/)?'
        r'((www|m)\.)?'
        r'(youtube\.com|youtu\.be)\/'
        r'(watch\?v=|shorts\/|embed\/|v\/|e\/|.*[?&]v=)?'
        r'([A-Za-z0-9._\-]{11})'
        r'.*$';
    final youtubeRegex = RegExp(youtubePattern, caseSensitive: false);
    return youtubeRegex.hasMatch(url.trim());
  }

  Future<InstagramDownloadResponse?> downloadYouTubeVideo(
    String youtubeUrl,
  ) async {
    if (isValidYouTubeUrl(youtubeUrl) == false) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Invalid URL"),
          content: const Text("Please enter a valid YouTube video URL."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return null;
    }

    final youtubeService = YouTubeVideoDownloadService();
    final response = await youtubeService.downloadYouTubeVideo(youtubeUrl);

    if (response != null && response.containsKey('s3Files')) {
      // Extract and store thumbnail URL from YouTube response
      final thumbnailUrl = response['thumbnail'] as String?;
      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        setState(() {
          thumnailImageURL = thumbnailUrl;
        });
        print("📸 YouTube thumbnail URL set: $thumbnailUrl");
      }

      // Store video resources with quality info for selection dialog
      if (response.containsKey('videoResources')) {
        _youtubeVideoResources = List<Map<String, dynamic>>.from(
          response['videoResources'] ?? [],
        );
        _lastYoutubeUrlWithResources = youtubeUrl.trim();
        print(
          "📦 Stored ${_youtubeVideoResources?.length} YouTube video qualities",
        );
      }

      return InstagramDownloadResponse(
        message: response['message'] ?? 'success',
        shortcode: response['shortcode'] ?? '',
        s3Files: List<String>.from(response['s3Files'] ?? []),
      );
    } else {
      if (!isDownloading && !_isRewardAdShowing) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: const Text(
              "Failed to download YouTube video. Please try again.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return null;
    }
  }

  Future<InstagramDownloadResponse?> downloadInstagramReel(
    String reelUrl,
  ) async {
    if (isValidInstagramUrl(reelUrl) == false) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Invalid URL"),
          content: const Text(
            "Please enter a valid Instagram or Facebook or Youtube video URL.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return null;
    }

    final url = "${ApiEndpoints.liveInstagramDownload}";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"url": reelUrl}),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          print("Parsed JSON: $jsonData");
          return InstagramDownloadResponse.fromJson(jsonData);
        } catch (e) {
          print("Error parsing JSON response: $e");
          if (!isDownloading && !_isRewardAdShowing) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Error"),
                content: Text("Failed to parse API response.\nError: $e"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
          return null;
        }
      }

      if (response.statusCode == 500) {
        print("API returned 500 error");
        if (!isDownloading && !_isRewardAdShowing) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Failed"),
              content: const Text(
                "Sorry, you can't able to download videos belongs to private account!!",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
        return null;
      }

      print("API returned non-200 status code: ${response.statusCode}");
      if (!isDownloading && !_isRewardAdShowing) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: Text(
              "Something went wrong."
              "\nStatus Code: ${response.statusCode}"
              "\nResponse: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }

      return null;
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Network Error"),
          content: Text("Something went wrong.\nError: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Stack(
          children: [
            AppBar(
              elevation: 0,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              title: Image.asset(
                'assets/images/InstaSave.png',
                height: 18,
                width: 78,
              ),
              actions: [
                if (!PremiumState.isPremium.value)
                  IconButton(
                    onPressed: isDownloading ||
                            (isLoading && !isDownloading) ||
                            _isRewardAdShowing
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubscriptionScreen(),
                              ),
                            );
                          },
                    icon: Image.asset(
                      'assets/images/adicon.png',
                      height: 30,
                      width: 64,
                    ),
                  ),
                IconButton(
                  onPressed:
                      isDownloading ||
                          (isLoading && !isDownloading) ||
                          _isRewardAdShowing
                      ? null // Disable button when condition is true
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WhatsappStatusSaverScreen(),
                            ),
                          );
                        },
                  icon: Image.asset(
                    'assets/images/whatsapp_logo.png',
                    height: 30,
                    width: 30,
                  ),
                ),
                IconButton(
                  onPressed:
                      isDownloading ||
                          (isLoading && !isDownloading) ||
                          _isRewardAdShowing
                      ? null // Disable button when condition is true
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InstagramLoginScreen(),
                            ),
                          );
                        },
                  icon: Image.asset(
                    'assets/images/instaicon.png',
                    height: 30,
                    width: 30,
                  ),
                ),
                IconButton(
                  onPressed:
                      isDownloading ||
                          (isLoading && !isDownloading) ||
                          _isRewardAdShowing
                      ? null // Disable button when condition is true
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(),
                            ),
                          );
                        },
                  icon: Image.asset(
                    'assets/images/menu.png',
                    height: 30,
                    width: 30,
                  ),
                ),
              ],
            ),
            if (isDownloading ||
                (isLoading && !isDownloading) ||
                _isRewardAdShowing)
              Positioned.fill(
                child: ModalBarrier(
                  color: Colors.black.withOpacity(0.7),
                  dismissible: false,
                ),
              ),
          ],
        ),
      ),

      body: Stack(
        children: [
          // Main Content
          if (isDownloaded)
            DownloadedVideoScreen()
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: isHome
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _urlController,
                                    enabled:
                                        !isDownloading && !_isRewardAdShowing,
                                    onChanged: (value) {
                                      print(value);
                                      inputUserURL = value;
                                      if (_lastProcessedClipboardUrl !=
                                          value.trim()) {
                                        _lastProcessedClipboardUrl = null;
                                      }
                                      if (value.isEmpty) {
                                        isTextFiledEmpty = true;
                                      } else {
                                        isTextFiledEmpty = false;
                                      }
                                      setState(() {});
                                    },
                                    onTap: () {
                                      // Check if user is manually pasting a link
                                      // We'll handle this through the onChanged callback
                                    },
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(
                                        context,
                                      ).translate("dropInstaLink"),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 20,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: const BorderSide(
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: const BorderSide(
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Medium Rectangle Ad
                                  if (!PremiumState.isPremium.value &&
                                      _isMediumRectangleAdReady &&
                                      _nativeAdService.mediumRectangleAd !=
                                          null)
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      alignment: Alignment.center,
                                      height:
                                          250, // Fixed height for medium rectangle ad (300x250)
                                      width:
                                          300, // Fixed width for medium rectangle ad
                                      child: AdWidget(
                                        ad: _nativeAdService.mediumRectangleAd!,
                                      ),
                                    ),
                                  // Spacer to push download button to bottom - always maintains position above bottom nav
                                  SizedBox(
                                    height: () {
                                      if (MediaQuery.of(
                                            context,
                                          ).viewInsets.bottom >
                                          0) {
                                        return 20.0;
                                      }
                                      final calculatedHeight =
                                          constraints.maxHeight -
                                          (10 +
                                              52 +
                                              10 + // top spacing + textfield + spacing
                                              (_isMediumRectangleAdReady &&
                                                      _nativeAdService
                                                              .mediumRectangleAd !=
                                                          null
                                                  ? 270
                                                  : 0) + // ad height + margins
                                              30 + // bottom spacing before button
                                              55); // button height
                                      return calculatedHeight > 0
                                          ? calculatedHeight
                                          : 20.0;
                                    }(),
                                  ),
                                  const SizedBox(height: 30),
                                  isTextFiledEmpty
                                      ? const SizedBox()
                                      : SizedBox(
                                          width: double.infinity,
                                          child: GradientDownloadButton(
                                            onTap: () {
                                              if (!isDownloading &&
                                                  !_isRewardAdShowing) {
                                                print(inputUserURL);
                                                // Show interstitial ad when user taps download button
                                                _showInterstitialAdOnLinkPaste();
                                                inputInstagramReeDownlodlLink(
                                                  inputUserURL,
                                                );
                                              }
                                            },
                                            isImageShow: true,
                                            title: 'download',
                                            isEnabled:
                                                !isDownloading &&
                                                !_isRewardAdShowing,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : RecentlyVisitedScreen(),
              ),
            ),
          // Full-screen blocking overlay with progress indicator
          if (isDownloading || _isRewardAdShowing)
            ModalBarrier(
              color: Colors.black.withOpacity(0.7),
              dismissible: false,
            ),
          // Progress Indicator
          if (isDownloading)
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: downloadProgress / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFE1306C),
                            ),
                          ),
                        ),
                        Text(
                          '${downloadProgress.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFFE1306C),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Downloading Video...',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          // Reward Ad Loading Indicator
          if (_isRewardAdShowing && !isDownloading)
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFE1306C),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Loading Ad...',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Watch the ad for 30 seconds\nto start download',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          // Processing overlay
          if (isLoading && !isDownloading && !_isRewardAdShowing)
            ModalBarrier(
              color: Colors.black.withOpacity(0.7),
              dismissible: false,
            ),
          if (isLoading && !isDownloading && !_isRewardAdShowing)
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFE1306C),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Processing...',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Bottom Navigation Bar
      bottomNavigationBar:
          isDownloading || (isLoading && !isDownloading) || _isRewardAdShowing
          ? null
          : SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Navigation Bar
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: InstagramGradientButton(
                      onTabChange: (index) {
                        setState(() {
                          if (index == 1) {
                            isDownloaded = true;
                          } else {
                            isDownloaded = false;
                          }
                        });
                      },
                      isEnabled: !isDownloading && !_isRewardAdShowing,
                    ),
                  ),
                  // Banner Ad below the navigation bar
                  if (!PremiumState.isPremium.value &&
                      _isBannerAdReady &&
                      _bannerAd != null &&
                      !isDownloading &&
                      !isLoading &&
                      !_isRewardAdShowing &&
                      mounted)
                    Container(
                      width: double.infinity,
                      height: _bannerAd?.size.height.toDouble() ?? 50,
                      alignment: Alignment.center,
                      color: Colors.transparent,
                      child: AdWidget(ad: _bannerAd!),
                    ),
                ],
              ),
            ),
    );
  }
}

class GradientDownloadButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isImageShow;
  final String title;
  final bool isEnabled;

  GradientDownloadButton({
    super.key,
    required this.onTap,
    required this.isImageShow,
    required this.title,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? [
                    Color(0xFF833AB4),
                    Color(0xFFE1306C),
                    Color(0xFFF77737),
                    Color(0xFFFFDC80),
                  ]
                : [Colors.grey, Colors.grey.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isImageShow
                  ? Icon(Icons.download, color: Colors.white, size: 22)
                  : SizedBox(),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).translate(title),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentlyVisitedScreen extends StatelessWidget {
  RecentlyVisitedScreen({super.key});
  final List<Map<String, String>> users = [
    {
      "name": "john_doe",
      "image": "https://picsum.photos/seed/pic1/100",
      "thumb": "https://picsum.photos/id/1020/200/200",
      "des": "6:00 PM (Noon) અમદાવાદ થી દ્વારકા વંદે ભારત માં...",
    },
    {
      "name": "James_mart",
      "image": "https://picsum.photos/seed/pic2/100",
      "thumb": "https://picsum.photos/id/1011/200/200",
      "des": "6:00 PM (Noon) અમદાવાદ થી દ્વારકા વંદે ભારત માં...",
    },
    {
      "name": "Mr_happy",
      "image": "https://picsum.photos/seed/pic3/100",
      "thumb": "https://picsum.photos/id/1012/200/200",
      "des": "6:00 PM (Noon) અમદાવાદ થી દ્વારકા વંદે ભારત માં...",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Drop your Insta link here",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Recently Visited",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "View All",
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Image.network(user["thumb"]!, fit: BoxFit.cover),
                            ],
                          ),
                        ),
                        title: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(
                                  Icons.person,
                                  size: 12,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                            Text(
                              user["name"]!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          crossAxisAlignment: CrossAxisAlignment.start,
                        ),
                        subtitle: Text(
                          user["des"]!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: GestureDetector(
                          onTap: () {
                            print(" tap");
                            showCollectionSheet(context);
                          },
                          child: const Icon(
                            Icons.bookmark_border,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showCollectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CollectionBottomSheet(),
    );
  }
}

class InstagramGradientButton extends StatefulWidget {
  final Function(int) onTabChange;
  final bool isEnabled;

  const InstagramGradientButton({
    Key? key,
    required this.onTabChange,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<InstagramGradientButton> createState() =>
      _InstagramGradientButtonState();
}

class _InstagramGradientButtonState extends State<InstagramGradientButton> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isEnabled
              ? [
                  Color(0xFF833AB4),
                  Color(0xFFE1306C),
                  Color(0xFFF77737),
                  Color(0xFFFFDC80),
                ]
              : [Colors.grey, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: widget.isEnabled
                  ? () {
                      widget.onTabChange(0);
                      setState(() => selectedIndex = 0);
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home,
                      size: 20,
                      color: selectedIndex == 0
                          ? Colors.pink
                          : widget.isEnabled
                          ? Colors.white
                          : Colors.grey.shade300,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).translate("home"),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selectedIndex == 0
                              ? Colors.pink
                              : widget.isEnabled
                              ? Colors.white
                              : Colors.grey.shade300,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: widget.isEnabled
                  ? () {
                      widget.onTabChange(1);
                      setState(() => selectedIndex = 1);
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.download,
                      size: 20,
                      color: selectedIndex == 1
                          ? Colors.pink
                          : widget.isEnabled
                          ? Colors.white
                          : Colors.grey.shade300,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).translate("recentDownloads"),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selectedIndex == 1
                              ? Colors.pink
                              : widget.isEnabled
                              ? Colors.white
                              : Colors.grey.shade300,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _CollectionBottomSheet extends StatelessWidget {
  const _CollectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/images/collection.png",
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Collection for",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.bookmark_border, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Collections",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                "+New Collection",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.pink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCollectionItem("Spiritual", "assets/images/collectionSpi.png"),
          _buildCollectionItem(
            "UI Design",
            "assets/images/collectionDesign.png",
          ),
          _buildCollectionItem("Movies", "assets/images/collection.png"),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCollectionItem(String title, String img) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(img, height: 40, width: 40, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: const Icon(Icons.add, size: 16),
          ),
        ],
      ),
    );
  }
}
