import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iptv_demo/ads/ad_config.dart';
import 'package:iptv_demo/ads/ima_ad_service.dart';
import 'package:iptv_demo/ads/interstitial_ad_manager.dart';
import 'package:iptv_demo/ads/premium_bottom_sheet.dart';
import 'package:iptv_demo/ima/ima_player.dart';
import 'package:iptv_demo/utils/premium_access.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Opens the live stream for [channel], respecting premium / ad gate.
void openChannelPlayer(IptvChannel channel) {
  if (userHasPremiumAccess) {
    Get.to(() => PlayerScreen(channel: channel));
    return;
  }
  InterstitialAdManager.instance.preload();
  showModalBottomSheet<void>(
    context: Get.context!,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (_) => PremiumBottomSheet(
      channel: channel,
      onChannelUnlocked: () => Get.to(() => PlayerScreen(channel: channel)),
    ),
  );
}

enum _VideoDisplayMode { fit, stretch, crop }

class PlayerScreen extends StatefulWidget {
  final IptvChannel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player player;
  late final VideoController controller;
  bool _mediaOpened = false;
  bool _showVideoSurface = false;
  bool _isPlayingAd = false;
  bool _playbackStarted = false;
  String? _errorMessage;
  bool _isFullscreen = false;
  bool _isFullscreenTransitioning = false;
  _VideoDisplayMode _displayMode = _VideoDisplayMode.fit;
  bool _uiPlaying = true;
  StreamSubscription<bool>? _playingSub;
  late final ImaAdService _imaAdService;

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
    _imaAdService = ImaAdService();
    _initializeVideo();
  }

  BoxFit _videoFitForMode(_VideoDisplayMode mode) {
    switch (mode) {
      case _VideoDisplayMode.fit:
        return BoxFit.contain;
      case _VideoDisplayMode.stretch:
        return BoxFit.fill;
      case _VideoDisplayMode.crop:
        return BoxFit.cover;
    }
  }

  IconData _displayModeIcon(_VideoDisplayMode mode) {
    switch (mode) {
      case _VideoDisplayMode.fit:
        return Icons.fit_screen;
      case _VideoDisplayMode.stretch:
        return Icons.open_in_full;
      case _VideoDisplayMode.crop:
        return Icons.crop;
    }
  }

  void _cycleDisplayMode() {
    setState(() {
      _displayMode = switch (_displayMode) {
        _VideoDisplayMode.fit => _VideoDisplayMode.stretch,
        _VideoDisplayMode.stretch => _VideoDisplayMode.crop,
        _VideoDisplayMode.crop => _VideoDisplayMode.fit,
      };
    });
  }

  void _openChannelSchedule() {
    Get.toNamed(
      AppRoutes.CHANNEL_SCHEDULE,
      arguments: widget.channel,
    );
  }

  /// Portrait uses ScreenUtil; landscape uses fixed px — `.sp` scales too large
  /// when the device is rotated and blows up the overlay title.
  double _channelTitleFontSize({required bool isLandscape}) {
    final length = widget.channel.title.trim().length;
    if (isLandscape) {
      if (length >= 42) return 13;
      if (length >= 28) return 14;
      return 15;
    }
    if (length >= 42) return 16.sp;
    if (length >= 28) return 18.sp;
    return 20.sp;
  }

  Widget _channelTitleText({required bool isLandscape}) {
    return CustomText(
      widget.channel.title,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      color: AppColors.white,
      fontFamily: AppStrings.interBold,
      fontWeight: FontWeight.w700,
      fontSize: _channelTitleFontSize(isLandscape: isLandscape),
      height: isLandscape ? 1.2 : null,
    );
  }

  Future<void> _playImaAd() async {
    await _imaAdService.playBreak(
      adTagUrl: AdConfig.mobileVastUrl,
      onStateChanged: (isPlaying) {
        if (!mounted) return;
        setState(() {
          _isPlayingAd = isPlaying;
          if (isPlaying) {
            _showVideoSurface = true;
            _playbackStarted = false;
            player.pause();
          } else {
            _playbackStarted = false;
          }
        });
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _isPlayingAd = false;
        });
        showAppToast(
          title: 'No ads available',
          message: 'Please continue watching.',
          isError: false,
        );
      },
    );
  }

  /// Same row as the channel title when there is no [AppBar] (landscape).
  Widget _buildLandscapeTitleBar() {
    return Material(
      color: AppColors.black,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 22),
              color: AppColors.white,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: () => Get.back(),
            ),
            Expanded(
              child: _channelTitleText(isLandscape: true),
            ),
            IconButton(
              tooltip: 'Channel schedule',
              onPressed: _openChannelSchedule,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(Icons.dvr_rounded,
                  color: AppColors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  String _qualityLabel(VideoTrack track) {
    if (track.id == 'auto') return 'Auto';
    if (track.id == 'no') return 'Disabled';
    final height = track.h;
    final bitrate = track.bitrate;
    if (height != null && height > 0) {
      return '${height}p';
    }
    if (bitrate != null && bitrate > 0) {
      final kbps = (bitrate / 1000).round();
      return '$kbps kbps';
    }
    return track.title?.trim().isNotEmpty == true
        ? track.title!.trim()
        : 'Quality ${track.id}';
  }

  List<VideoTrack> _availableQualityTracks(Tracks tracks) {
    return tracks.video.where((track) => track.id != 'no').toList();
  }

  Future<void> _selectQuality(VideoTrack track) async {
    try {
      await player.setVideoTrack(track);
      if (!mounted) return;
      showAppToast(
        title: 'Quality',
        message: 'Switched to ${_qualityLabel(track)}',
      );
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        title: 'Error',
        message: 'Unable to switch quality: $e',
        isError: true,
      );
    }
  }

  String _formatDuration(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString();
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _enterFullscreen() async {
    if (_isFullscreenTransitioning || _isFullscreen) return;
    _isFullscreenTransitioning = true;
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (mounted) {
        setState(() {
          _isFullscreen = true;
        });
      }
    } finally {
      _isFullscreenTransitioning = false;
    }
  }

  Future<void> _exitFullscreen({bool updateState = true}) async {
    if (_isFullscreenTransitioning || !_isFullscreen) return;
    _isFullscreenTransitioning = true;
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      if (updateState && mounted) {
        setState(() {
          _isFullscreen = false;
        });
      }
    } finally {
      _isFullscreenTransitioning = false;
    }
  }

  Future<void> _toggleFullscreen() async {
    if (_isFullscreen) {
      await _exitFullscreen();
    } else {
      await _enterFullscreen();
    }
  }

  Future<void> _initializeVideo() async {
    debugPrint(
        '[_initializeVideo] Starting for channel: ${widget.channel.title} (ID: ${widget.channel.channelId})');
    try {
      String? streamUrl;

      if (widget.channel.url.isNotEmpty) {
        streamUrl = widget.channel.url;
        debugPrint('[_initializeVideo] Using hardcoded URL: $streamUrl');
      } else if (widget.channel.streamChannelId.isNotEmpty) {
        debugPrint(
            '[_initializeVideo] Fetching stream URL for ID: ${widget.channel.streamChannelId}');
        final controller = Get.find<IptvController>();
        streamUrl =
            await controller.fetchStreamUrl(widget.channel.streamChannelId);
        debugPrint('[_initializeVideo] Fetched stream URL: $streamUrl');
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        debugPrint('[_initializeVideo] No stream URL found.');
        if (mounted) {
          setState(() {
            _errorMessage = widget.channel.streamChannelId.isNotEmpty
                ? 'Could not find any streams for this channel.'
                : 'No stream URL for this channel yet. Add a stream source when your API provides it.';
          });
        }
        return;
      }

      if (shouldShowAdsToUser) {
        debugPrint('[_initializeVideo] Playing pre-roll IMA ad');
        if (mounted) {
          setState(() {
            _isPlayingAd = true;
            _showVideoSurface = true;
            _playbackStarted = false;
          });
        }
        try {
          player.pause();
          await _playImaAd();
        } catch (e) {
          debugPrint('[_initializeVideo] IMA pre-roll failed: $e');
        }
      }

      debugPrint('[_initializeVideo] Opening main content');

      await player
          .open(
        Media(streamUrl),
        play: true,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('[_initializeVideo] Opening media timed out.');
          throw TimeoutException(
              'The video stream is taking too long to respond.');
        },
      );
      debugPrint('[_initializeVideo] Media opened successfully.');

      debugPrint('[_initializeVideo] Autoplay requested with open().');

      _playingSub?.cancel();
      _playingSub = player.stream.playing.listen((playing) {
        if (!mounted) return;
        setState(() {
          if (playing && !_playbackStarted) _playbackStarted = true;
          _uiPlaying = playing;
        });
      });
      if (mounted) {
        final playing = player.state.playing;
        setState(() {
          _showVideoSurface = true;
          _mediaOpened = true;
          _playbackStarted = playing;
          _uiPlaying = playing;
        });
      }
    } catch (e) {
      debugPrint('[_initializeVideo] Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        showAppToast(
          title: 'Error',
          message: 'Error loading video: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    try {
      _playingSub?.cancel();
      _imaAdService.dispose();
      unawaited(_exitFullscreen(updateState: false));
      player.dispose();
    } catch (e) {
      debugPrint('Error disposing player: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return PopScope(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isFullscreen) {
          _exitFullscreen();
        }
      },
      child: Scaffold(
        appBar: isLandscape
            ? null
            : AppBar(
                titleSpacing: 0,
                title: _channelTitleText(isLandscape: false),
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                actions: [
                  IconButton(
                    tooltip: 'Channel schedule',
                    onPressed: _openChannelSchedule,
                    icon: const Icon(Icons.dvr_rounded),
                  ),
                ],
              ),
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: _showVideoSurface || _mediaOpened
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: Video(
                        controller: controller,
                        fit: _videoFitForMode(_displayMode),
                        controls: (_) => const SizedBox.shrink(),
                      ),
                    ),
                    if (!_playbackStarted && !_isPlayingAd)
                      Positioned.fill(
                        child: ColoredBox(
                          color: AppColors.black,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: AppColors.white,
                                ),
                                16.verticalSpace,
                                CustomText(
                                  AppStrings.loadingVideo,
                                  color: AppColors.white,
                                  fontFamily: AppStrings.interRegular,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_isPlayingAd)
                      Positioned.fill(
                        child: ColoredBox(
                          color: AppColors.black,
                          child: SafeArea(
                            child: ImaPlayerWidget(
                              controller: _imaAdService.controller,
                              height: null,
                            ),
                          ),
                        ),
                      ),
                    if (_isPlayingAd)
                      Positioned(
                        top: isLandscape ? 52 : 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: CustomText(
                            'Ad',
                            color: AppColors.white,
                            fontSize: isLandscape ? 12 : 12.sp,
                            fontFamily: AppStrings.interSemiBold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (isLandscape)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildLandscapeTitleBar(),
                      ),
                    if (_mediaOpened && !_isPlayingAd)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SafeArea(
                          top: false,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            color: AppColors.black.withValues(alpha: 0.28),
                            child: StreamBuilder<Duration>(
                              stream: player.stream.position,
                              builder: (context, positionSnapshot) {
                                return StreamBuilder<Duration>(
                                  stream: player.stream.duration,
                                  builder: (context, durationSnapshot) {
                                    final position =
                                        positionSnapshot.data ?? Duration.zero;
                                    final duration =
                                        durationSnapshot.data ?? Duration.zero;
                                    final safeDuration =
                                        duration.inMilliseconds <= 0
                                            ? const Duration(milliseconds: 1)
                                            : duration;
                                    final sliderValue = position.inMilliseconds
                                        .clamp(0, safeDuration.inMilliseconds)
                                        .toDouble();

                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SliderTheme(
                                          data:
                                              SliderTheme.of(context).copyWith(
                                            trackHeight: 3,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                              enabledThumbRadius: 7,
                                            ),
                                          ),
                                          child: Slider(
                                            min: 0,
                                            max: safeDuration.inMilliseconds
                                                .toDouble(),
                                            value: sliderValue,
                                            activeColor:
                                                AppColors.playerSliderActive,
                                            inactiveColor: AppColors.white
                                                .withValues(alpha: 0.5),
                                            onChanged: (value) {
                                              player.seek(
                                                Duration(
                                                  milliseconds: value.round(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            StreamBuilder<bool>(
                                              stream: player.stream.playing,
                                              builder:
                                                  (context, playingSnapshot) {
                                                return IconButton(
                                                  onPressed: () {
                                                    if (_uiPlaying) {
                                                      player.pause();
                                                      setState(() =>
                                                          _uiPlaying = false);
                                                    } else {
                                                      player.play();
                                                      setState(() =>
                                                          _uiPlaying = true);
                                                    }
                                                  },
                                                  icon: Icon(
                                                    _uiPlaying
                                                        ? Icons.pause
                                                        : Icons.play_arrow,
                                                    color: AppColors.white,
                                                  ),
                                                );
                                              },
                                            ),
                                            8.horizontalSpace,
                                            CustomText(
                                              '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                              color: AppColors.white,
                                              fontSize: 14,
                                              maxLines: 1,
                                            ),
                                            const Spacer(),
                                            StreamBuilder<Tracks>(
                                              stream: player.stream.tracks,
                                              initialData: player.state.tracks,
                                              builder:
                                                  (context, tracksSnapshot) {
                                                final tracks =
                                                    _availableQualityTracks(
                                                  tracksSnapshot.data ??
                                                      const Tracks(),
                                                );
                                                if (tracks.length <= 1) {
                                                  return const SizedBox
                                                      .shrink();
                                                }
                                                return StreamBuilder<Track>(
                                                  stream: player.stream.track,
                                                  initialData:
                                                      player.state.track,
                                                  builder: (context,
                                                      activeSnapshot) {
                                                    final activeTrack =
                                                        activeSnapshot
                                                            .data?.video;
                                                    return PopupMenuButton<
                                                        VideoTrack>(
                                                      tooltip: 'Video quality',
                                                      onSelected:
                                                          _selectQuality,
                                                      itemBuilder: (_) {
                                                        return tracks
                                                            .map(
                                                              (track) =>
                                                                  PopupMenuItem<
                                                                      VideoTrack>(
                                                                value: track,
                                                                child: Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          Text(
                                                                        _qualityLabel(
                                                                          track,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    if (activeTrack ==
                                                                        track)
                                                                      const Icon(
                                                                        Icons
                                                                            .check,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                            )
                                                            .toList();
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons.hd,
                                                              color: AppColors
                                                                  .white,
                                                            ),
                                                            4.horizontalSpace,
                                                            CustomText(
                                                              _qualityLabel(
                                                                activeTrack ??
                                                                    tracks
                                                                        .first,
                                                              ),
                                                              color: AppColors
                                                                  .white,
                                                              fontSize: 12,
                                                              maxLines: 1,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            IconButton(
                                              onPressed: _cycleDisplayMode,
                                              icon: Icon(
                                                _displayModeIcon(_displayMode),
                                                color: AppColors.white,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: _toggleFullscreen,
                                              icon: Icon(
                                                _isFullscreen
                                                    ? Icons.fullscreen_exit
                                                    : Icons.fullscreen,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_errorMessage == null) ...[
                          const CircularProgressIndicator(
                              color: AppColors.white),
                          16.verticalSpace,
                          CustomText(
                            AppStrings.loadingVideo,
                            color: AppColors.white,
                            fontFamily: AppStrings.interRegular,
                          ),
                        ] else ...[
                          Icon(
                            Icons.info_outline,
                            color: AppColors.white.withValues(alpha: 0.85),
                            size: 48,
                          ),
                          16.verticalSpace,
                          CustomText(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            color: AppColors.white.withValues(alpha: 0.85),
                            fontFamily: AppStrings.interRegular,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
