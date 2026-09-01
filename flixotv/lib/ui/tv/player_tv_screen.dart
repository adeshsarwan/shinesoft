import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/ads/ad_config.dart';
import 'package:iptv_demo/ads/ad_mob_bootstrap.dart';
import 'package:iptv_demo/ads/ima_ad_service.dart';
import 'package:iptv_demo/ima/ima_player.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/utils/post_auth_home_route.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:iptv_demo/ui/tv/widgets/channel_schedule_overlay_tv.dart';
import 'package:iptv_demo/utils/premium_access.dart';
import 'package:iptv_demo/widgets/custom_text.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Opens the live stream on TV. Premium users play immediately; others see a
/// full-screen interstitial first (no watch-ad bottom sheet).
Future<void> openChannelPlayerTv(IptvChannel channel) async {
  if (userHasPremiumAccess) {
    Get.to(() => PlayerTvScreen(channel: channel));
    return;
  }

  final isTv = await isAndroidTvLeanbackDevice();
  if (isTv) {
    // TV: play immediately
    Get.to(() => PlayerTvScreen(channel: channel));
    return;
  }

  // Mobile: play immediately (ads removed)
  Get.to(() => PlayerTvScreen(channel: channel));
}

class PlayerTvScreen extends StatefulWidget {
  const PlayerTvScreen({super.key, required this.channel});
  final IptvChannel channel;
  @override
  State<PlayerTvScreen> createState() => _PlayerTvScreenState();
}

class _PlayerTvScreenState extends State<PlayerTvScreen> {
  static const _maxStreamOpenAttempts = 3;
  static const _streamOpenTimeout = Duration(seconds: 25);
  static const _postAdSettleDelay = Duration(milliseconds: 400);

  late final Player _player;
  late final VideoController _vc;

  bool _mediaOpened = false;
  bool _showVideoSurface = false;
  bool _isPlayingAd = false;
  bool _isOpeningContent = false;
  bool _playbackErrorRetried = false;
  bool _preRollAttempted = false;
  String? _adBreakLabel;
  bool _playbackStarted = false;
  String? _error;
  String? _streamUrl;
  bool _showControls = false;
  bool _showScheduleOverlay = false;
  Timer? _hideTimer;
  bool _uiPlaying = true;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<String>? _errorSub;
  late final ImaAdService _imaAdService;
  bool _isNavigatingBack = false;
  bool _playerDisposed = false;

  final _focusBack = FocusNode(debugLabel: 'back');
  final _focusSchedule = FocusNode(debugLabel: 'schedule');
  final _focusProgress = FocusNode(debugLabel: 'progress');
  final _focusPlay = FocusNode(debugLabel: 'play');
  final _focusQuality = FocusNode(debugLabel: 'quality');

  @override
  void initState() {
    super.initState();
    _player = Player();
    _vc = VideoController(_player);
    _imaAdService = ImaAdService();
    _errorSub = _player.stream.error.listen((error) {
      debugPrint('[PlayerTv] media error: $error');
      if (!mounted || _isPlayingAd || _isOpeningContent) return;
      unawaited(_handlePlaybackError());
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    HardwareKeyboard.instance.addHandler(_hwKey);
    _load();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_hwKey);
    _hideTimer?.cancel();
    _playingSub?.cancel();
    _errorSub?.cancel();
    _focusBack.dispose();
    _focusSchedule.dispose();
    _focusProgress.dispose();
    _focusPlay.dispose();
    _focusQuality.dispose();
    if (!_playerDisposed) {
      unawaited(_disposePlayer());
    }
    _imaAdService.dispose();
    super.dispose();
  }

  Future<void> _disposePlayer() async {
    if (_playerDisposed) return;
    _playerDisposed = true;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _player.dispose();
    } catch (e) {
      debugPrint('[PlayerTv] dispose error: $e');
    }
  }

  // Fires before Flutter routing / GetX back handling
  bool _hwKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final k = event.logicalKey;

    if (k == LogicalKeyboardKey.goBack ||
        k == LogicalKeyboardKey.escape ||
        k == LogicalKeyboardKey.browserBack ||
        k == LogicalKeyboardKey.backspace) {
      if (event is! KeyDownEvent) return true;
      if (_showScheduleOverlay) {
        _closeScheduleOverlay();
      } else if (_isPlayingAd) {
        unawaited(_handleBackDuringAd());
      } else if (_showControls) {
        _dismissControls();
      } else {
        unawaited(_back());
      }
      return true; // consumed
    }

    if (_showScheduleOverlay || _isPlayingAd) return false;

    if (k == LogicalKeyboardKey.mediaPlayPause) {
      _togglePlay();
      return true;
    }
    if (k == LogicalKeyboardKey.mediaPlay) {
      _player.play();
      if (mounted) setState(() => _uiPlaying = true);
      _bringUpControls();
      return true;
    }
    if (k == LogicalKeyboardKey.mediaPause) {
      _player.pause();
      if (mounted) setState(() => _uiPlaying = false);
      _bringUpControls();
      return true;
    }

    // Any d-pad key while controls hidden → show controls, consume
    if (!_showControls) {
      if (k == LogicalKeyboardKey.arrowUp ||
          k == LogicalKeyboardKey.arrowDown ||
          k == LogicalKeyboardKey.arrowLeft ||
          k == LogicalKeyboardKey.arrowRight ||
          k == LogicalKeyboardKey.select ||
          k == LogicalKeyboardKey.enter) {
        _bringUpControls();
        return true;
      }
    }

    // Controls visible — let Flutter move focus between buttons
    return false;
  }

  Future<void> _load() async {
    try {
      String? url;
      if (widget.channel.url.isNotEmpty) {
        url = widget.channel.url;
      } else if (widget.channel.streamChannelId.isNotEmpty) {
        url = await Get.find<IptvController>()
            .fetchStreamUrl(widget.channel.streamChannelId);
      }
      if (url == null || url.isEmpty) {
        if (mounted) setState(() => _error = 'No stream URL available.');
        return;
      }

      _streamUrl = url;

      if (shouldShowAdsToUser && !_preRollAttempted) {
        _preRollAttempted = true;
        if (mounted) {
          setState(() {
            _isPlayingAd = true;
            _playbackStarted = false;
            _showControls = false;
          });
        }
        // Let the IMA container mount in the view hierarchy before requesting ads.
        await WidgetsBinding.instance.endOfFrame;
        await WidgetsBinding.instance.endOfFrame;
        try {
          await _player.stop();
          await _playImaAd();
        } catch (e) {
          debugPrint('[PlayerTv] IMA pre-roll failed: $e');
        }
        if (!mounted) return;
        setState(() {
          _isPlayingAd = false;
          _adBreakLabel = null;
        });
        // Give the TV decoder time to release IMA resources before opening live TV.
        await Future<void>.delayed(_postAdSettleDelay);
        await WidgetsBinding.instance.endOfFrame;
      }

      if (!mounted) return;
      await _openMainContent(url);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _playImaAd() async {
    await AdMobBootstrap.whenReady;
    final adTagUrl = AdConfig.tvVastUrl;
    debugPrint('[PlayerTv] Playing pre-roll IMA ad');
    debugPrint('[PlayerTv] TV VAST tag (before IMA): $adTagUrl');

    // Let the IMA container mount in the view hierarchy before requesting ads.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 350));

    await _imaAdService.playBreak(
      adTagUrl: adTagUrl,
      onStateChanged: (isPlaying) {
        if (!mounted || !isPlaying) return;
        setState(() {
          _isPlayingAd = true;
          _adBreakLabel = 'Ad';
          _playbackStarted = false;
          _showControls = false;
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

  Future<void> _openMainContent(String url, {bool resetErrorRetry = true}) async {
    _isOpeningContent = true;
    if (resetErrorRetry) {
      _playbackErrorRetried = false;
    }

    if (mounted) {
      setState(() {
        _error = null;
        _showVideoSurface = true;
      });
    }
    await WidgetsBinding.instance.endOfFrame;

    Object? lastError;
    for (var attempt = 1; attempt <= _maxStreamOpenAttempts; attempt++) {
      if (!mounted) return;

      if (attempt > 1) {
        debugPrint(
          '[PlayerTv] Retrying stream open ($attempt/$_maxStreamOpenAttempts)',
        );
        try {
          await _player.stop();
        } catch (_) {}
        await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
      }

      try {
        await _player.open(Media(url), play: true).timeout(
              _streamOpenTimeout,
              onTimeout: () => throw TimeoutException('Stream timed out.'),
            );

        _bindPlayingListener();

        if (mounted) {
          final playing = _player.state.playing;
          setState(() {
            _mediaOpened = true;
            _playbackStarted = playing;
            _uiPlaying = playing;
          });
        }
        _isOpeningContent = false;
        return;
      } catch (e) {
        lastError = e;
        debugPrint('[PlayerTv] Stream open attempt $attempt failed: $e');
      }
    }

    _isOpeningContent = false;
    if (mounted) {
      setState(() {
        _error = lastError is TimeoutException
            ? 'Stream timed out. Try another channel.'
            : 'Playback error. Try another channel.';
      });
    }
  }

  void _bindPlayingListener() {
    _playingSub?.cancel();
    _playingSub = _player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() {
        if (playing && !_playbackStarted && !_isPlayingAd) {
          _playbackStarted = true;
        }
        _uiPlaying = playing;
      });
    });
  }

  Future<void> _handlePlaybackError() async {
    final url = _streamUrl;
    if (url == null || url.isEmpty || !mounted) return;

    if (!_playbackErrorRetried) {
      _playbackErrorRetried = true;
      debugPrint('[PlayerTv] Retrying playback after media error');
      await _openMainContent(url, resetErrorRetry: false);
      if (mounted && _error == null && _mediaOpened) return;
    }

    if (mounted) {
      setState(() => _error = 'Playback error. Try another channel.');
    }
  }

  Future<void> _resumeMainContent() async {
    final url = _streamUrl;
    if (url == null || url.isEmpty || !mounted) return;
    await _openMainContent(url);
  }

  Future<void> _handleBackDuringAd() async {
    if (_isPlayingAd && !_mediaOpened) {
      await _exitPlayer(skipPostRoll: true);
      return;
    }

    if (_isPlayingAd) {
      if (mounted) {
        setState(() {
          _isPlayingAd = false;
          _adBreakLabel = null;
        });
      }
      await _resumeMainContent();
    }
  }

  void _bringUpControls() {
    if (!mounted) return;
    setState(() => _showControls = true);
    _restartTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showControls) _focusPlay.requestFocus();
    });
  }

  void _dismissControls() {
    _hideTimer?.cancel();
    if (mounted) setState(() => _showControls = false);
  }

  void _openScheduleOverlay() {
    if (!mounted) return;
    _hideTimer?.cancel();
    setState(() {
      _showScheduleOverlay = true;
      _showControls = false;
    });
  }

  void _closeScheduleOverlay() {
    if (!mounted) return;
    setState(() => _showScheduleOverlay = false);
    _bringUpControls();
  }

  void _restartTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), _dismissControls);
  }

  void _togglePlay() {
    if (_uiPlaying) {
      _player.pause();
      if (mounted) setState(() => _uiPlaying = false);
    } else {
      _player.play();
      if (mounted) setState(() => _uiPlaying = true);
    }
    _bringUpControls();
  }

  static const int _seekStepMs = 5000;

  bool get _hasSeekableDuration => _player.state.duration.inMilliseconds > 0;

  void _focusBelowTopBar() {
    if (_hasSeekableDuration) {
      _focusProgress.requestFocus();
    } else {
      _focusPlay.requestFocus();
    }
  }

  void _focusAboveTransportRow() {
    if (_hasSeekableDuration) {
      _focusProgress.requestFocus();
    } else {
      _focusSchedule.requestFocus();
    }
  }

  void _seekByMilliseconds(int deltaMs) {
    final dur = _player.state.duration;
    if (dur.inMilliseconds <= 0) return;
    final pos = _player.state.position;
    final nextMs =
        (pos.inMilliseconds + deltaMs).clamp(0, dur.inMilliseconds).toInt();
    unawaited(_player.seek(Duration(milliseconds: nextMs)));
    _restartTimer();
  }

  bool _handleProgressKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp) {
      _focusSchedule.requestFocus();
      return true;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      _focusPlay.requestFocus();
      return true;
    }
    if (!_hasSeekableDuration) return false;
    if (k == LogicalKeyboardKey.arrowLeft) {
      _seekByMilliseconds(-_seekStepMs);
      return true;
    }
    if (k == LogicalKeyboardKey.arrowRight) {
      _seekByMilliseconds(_seekStepMs);
      return true;
    }
    return false;
  }

  bool _handlePlayKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp) {
      _focusAboveTransportRow();
      return true;
    }
    if (k == LogicalKeyboardKey.arrowRight &&
        _availableQualityTracks(_player.state.tracks).length > 1) {
      _focusQuality.requestFocus();
      return true;
    }
    return false;
  }

  bool _handleQualityKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp) {
      _focusAboveTransportRow();
      return true;
    }
    if (k == LogicalKeyboardKey.arrowLeft) {
      _focusPlay.requestFocus();
      return true;
    }
    return false;
  }

  bool _handleBackKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowDown) {
      _focusBelowTopBar();
      return true;
    }
    if (k == LogicalKeyboardKey.arrowRight) {
      _focusSchedule.requestFocus();
      return true;
    }
    return false;
  }

  bool _handleScheduleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowDown) {
      _focusBelowTopBar();
      return true;
    }
    if (k == LogicalKeyboardKey.arrowLeft) {
      _focusBack.requestFocus();
      return true;
    }
    return false;
  }

  Future<void> _back() async {
    await _exitPlayer();
  }

  Future<void> _exitPlayer({bool skipPostRoll = false}) async {
    if (_isNavigatingBack || !mounted) return;
    _isNavigatingBack = true;
    _hideTimer?.cancel();
    _playingSub?.cancel();
    _errorSub?.cancel();

    try {
      try {
        await _player.stop();
      } catch (_) {}
    } catch (e) {
      debugPrint('[PlayerTv] exit error: $e');
    }

    if (!mounted) {
      _isNavigatingBack = false;
      return;
    }

    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
    _isNavigatingBack = false;
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _qualityLabel(VideoTrack track) {
    if (track.id == 'auto') return 'Auto';
    if (track.id == 'no') return 'Disabled';
    final height = track.h;
    final bitrate = track.bitrate;
    if (height != null && height > 0) return '${height}p';
    if (bitrate != null && bitrate > 0)
      return '${(bitrate / 1000).round()} kbps';
    return track.title?.trim().isNotEmpty == true
        ? track.title!.trim()
        : 'Quality ${track.id}';
  }

  List<VideoTrack> _availableQualityTracks(Tracks tracks) {
    return tracks.video.where((track) => track.id != 'no').toList();
  }

  Future<void> _openQualityPicker() async {
    final tracks = _availableQualityTracks(_player.state.tracks);
    if (tracks.length <= 1 || !mounted) return;
    final selected = await showDialog<VideoTrack>(
      context: context,
      builder: (context) {
        final activeTrack = _player.state.track.video;
        return AlertDialog(
          backgroundColor: AppColors.black,
          title: const CustomText(
            'Select quality',
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            maxLines: 1,
          ),
          content: SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: tracks
                  .map(
                    (track) => ListTile(
                      autofocus: activeTrack == track,
                      title: CustomText(
                        _qualityLabel(track),
                        color: AppColors.white,
                        maxLines: 1,
                      ),
                      trailing: activeTrack == track
                          ? const Icon(Icons.check, color: AppColors.white)
                          : null,
                      onTap: () => Navigator.of(context).pop(track),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
    if (selected == null) return;
    await _player.setVideoTrack(selected);
    if (!mounted) return;
    _restartTimer();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showScheduleOverlay) {
          _closeScheduleOverlay();
          return false;
        }
        if (_isPlayingAd) {
          await _handleBackDuringAd();
          return false;
        }
        if (_showControls) {
          _dismissControls();
          return false;
        }
        await _exitPlayer();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: _error != null
            ? _buildLoadingOrError()
            : _isPlayingAd
                ? _buildAdOnly()
                : (_showVideoSurface || _mediaOpened)
                    ? _buildPlayer()
                    : _buildLoadingOrError(),
      ),
    );
  }

  Widget _buildLoadingOrError() {
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.white54, size: 56),
          16.verticalSpace,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: CustomText(
              _error!,
              textAlign: TextAlign.center,
              color: AppColors.white70,
              fontSize: 15,
            ),
          ),
          24.verticalSpace,
          ElevatedButton.icon(
            autofocus: true,
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
            label: const CustomText('Go Back', maxLines: 1),
          ),
        ]),
      );
    }
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppColors.white),
        16.verticalSpace,
        CustomText(
          'Loading ${widget.channel.title}…',
          color: AppColors.white70,
          fontSize: 15,
          maxLines: 1,
        ),
      ]),
    );
  }

  Widget _buildPlaybackLoader() {
    return ColoredBox(
      color: AppColors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.white),
            16.verticalSpace,
            CustomText(
              'Loading ${widget.channel.title}…',
              color: AppColors.white70,
              fontSize: 15,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdOnly() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.black),
        SafeArea(
          child: ImaPlayerWidget(
            controller: _imaAdService.controller,
            height: null,
          ),
        ),
        if (_adBreakLabel != null)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(4),
              ),
              child: CustomText(
                _adBreakLabel!,
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                maxLines: 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video — ValueKey forces rebuild when fit changes
        Video(
          controller: _vc,
          fit: BoxFit.contain,
          controls: (_) => const SizedBox.shrink(),
        ),

        if (!_playbackStarted) _buildPlaybackLoader(),

        // Controls overlay
        if (_showControls) _buildControls(),

        // Channel schedule drawer (same guides API as mobile)
        if (_showScheduleOverlay)
          ChannelScheduleOverlayTv(
            channel: widget.channel,
            onClose: _closeScheduleOverlay,
          ),
      ],
    );
  }

  Widget _buildControls() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Scrim
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.playerScrim,
                AppColors.transparent,
                AppColors.transparent,
                AppColors.playerScrim,
              ],
              stops: [0.0, 0.3, 0.65, 1.0],
            ),
          ),
        ),

        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
            child: Row(children: [
              _TvBtn(
                focusNode: _focusBack,
                onPressed: _back,
                onActivity: _restartTimer,
                onDirectionalKey: _handleBackKey,
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.white, size: 22),
              ),
              8.horizontalSpace,
              Expanded(
                child: CustomText(
                  widget.channel.title,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                ),
              ),
              _TvBtn(
                focusNode: _focusSchedule,
                onPressed: _openScheduleOverlay,
                onActivity: _restartTimer,
                onDirectionalKey: _handleScheduleKey,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dvr_rounded, color: AppColors.white, size: 22),
                    SizedBox(width: 6),
                    CustomText(
                      'Schedule',
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),

        // Bottom bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomBar(),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      color: AppColors.black.withValues(alpha: 0.55),
      child: StreamBuilder<Duration>(
        stream: _player.stream.position,
        builder: (_, posSnap) => StreamBuilder<Duration>(
          stream: _player.stream.duration,
          builder: (_, durSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final dur = durSnap.data ?? Duration.zero;
            final isLive = dur.inMilliseconds <= 0;
            final safeDur = isLive ? const Duration(milliseconds: 1) : dur;
            final sliderVal =
                pos.inMilliseconds.clamp(0, safeDur.inMilliseconds).toDouble();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TvSeekBar(
                  focusNode: _focusProgress,
                  enabled: !isLive,
                  value: sliderVal,
                  max: safeDur.inMilliseconds.toDouble(),
                  onSeek: (v) {
                    _player.seek(Duration(milliseconds: v.round()));
                    _restartTimer();
                  },
                  onDirectionalKey: _handleProgressKey,
                  onActivity: _restartTimer,
                ),

                // Buttons
                Row(children: [
                  // Play / Pause
                  StreamBuilder<bool>(
                    stream: _player.stream.playing,
                    initialData: _player.state.playing,
                    builder: (_, snap) {
                      return _TvBtn(
                        focusNode: _focusPlay,
                        onPressed: () {
                          if (_uiPlaying) {
                            _player.pause();
                            setState(() => _uiPlaying = false);
                          } else {
                            _player.play();
                            setState(() => _uiPlaying = true);
                          }
                          _restartTimer();
                        },
                        onActivity: _restartTimer,
                        onDirectionalKey: _handlePlayKey,
                        child: Icon(
                          _uiPlaying ? Icons.pause : Icons.play_arrow,
                          color: AppColors.white,
                          size: 28,
                        ),
                      );
                    },
                  ),
                  12.horizontalSpace,

                  // LIVE / time
                  if (isLive)
                    _liveBadge()
                  else
                    CustomText(
                      '${_fmt(pos)} / ${_fmt(dur)}',
                      color: AppColors.white,
                      fontSize: 13,
                      maxLines: 1,
                    ),

                  const Spacer(),
                  StreamBuilder<Tracks>(
                    stream: _player.stream.tracks,
                    initialData: _player.state.tracks,
                    builder: (_, tracksSnap) {
                      final tracks = _availableQualityTracks(
                        tracksSnap.data ?? const Tracks(),
                      );
                      if (tracks.length <= 1) {
                        return const SizedBox.shrink();
                      }
                      return StreamBuilder<Track>(
                        stream: _player.stream.track,
                        initialData: _player.state.track,
                        builder: (_, activeSnap) {
                          final activeTrack = activeSnap.data?.video;
                          return _TvBtn(
                            focusNode: _focusQuality,
                            onPressed: _openQualityPicker,
                            onActivity: _restartTimer,
                            onDirectionalKey: _handleQualityKey,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.hd,
                                  color: AppColors.white,
                                  size: 24,
                                ),
                                6.horizontalSpace,
                                CustomText(
                                  _qualityLabel(activeTrack ?? tracks.first),
                                  color: AppColors.white,
                                  fontSize: 13,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  12.horizontalSpace,
                ]),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _liveBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: AppColors.danger, borderRadius: BorderRadius.circular(4)),
        child: const CustomText(
          '● LIVE',
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          maxLines: 1,
        ),
      );
}

// ── TV button ─────────────────────────────────────────────────────────────────

typedef _TvDirectionalKeyHandler = bool Function(
    FocusNode node, KeyEvent event);

class _TvBtn extends StatefulWidget {
  const _TvBtn({
    required this.focusNode,
    required this.onPressed,
    required this.onActivity,
    required this.child,
    this.onDirectionalKey,
  });

  final FocusNode focusNode;
  final VoidCallback onPressed;
  final VoidCallback onActivity;
  final Widget child;
  final _TvDirectionalKeyHandler? onDirectionalKey;

  @override
  State<_TvBtn> createState() => _TvBtnState();
}

class _TvBtnState extends State<_TvBtn> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (f) {
        setState(() => _focused = f);
        if (f) widget.onActivity();
      },
      onKeyEvent: (node, e) {
        if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final k = e.logicalKey;
        if (k == LogicalKeyboardKey.select ||
            k == LogicalKeyboardKey.enter ||
            k == LogicalKeyboardKey.space) {
          if (e is KeyDownEvent) widget.onPressed();
          return KeyEventResult.handled;
        }
        if (widget.onDirectionalKey?.call(node, e) == true) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _focused
                ? AppColors.white.withValues(alpha: 0.25)
                : AppColors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border:
                _focused ? Border.all(color: AppColors.white, width: 2) : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── TV seek bar (left/right seek, up/down move focus) ─────────────────────────

class _TvSeekBar extends StatefulWidget {
  const _TvSeekBar({
    required this.focusNode,
    required this.enabled,
    required this.value,
    required this.max,
    required this.onSeek,
    required this.onDirectionalKey,
    required this.onActivity,
  });

  final FocusNode focusNode;
  final bool enabled;
  final double value;
  final double max;
  final ValueChanged<double> onSeek;
  final _TvDirectionalKeyHandler onDirectionalKey;
  final VoidCallback onActivity;

  @override
  State<_TvSeekBar> createState() => _TvSeekBarState();
}

class _TvSeekBarState extends State<_TvSeekBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      descendantsAreFocusable: false,
      onFocusChange: (f) {
        setState(() => _focused = f);
        if (f) widget.onActivity();
      },
      onKeyEvent: (node, event) {
        if (widget.onDirectionalKey(node, event)) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: _focused ? 6 : 4,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: widget.enabled ? (_focused ? 9 : 7) : 0,
            ),
            activeTrackColor: _focused
                ? AppColors.playerSliderActive
                : AppColors.playerSliderActive.withValues(alpha: 0.85),
            inactiveTrackColor: _focused
                ? AppColors.white.withValues(alpha: 0.55)
                : AppColors.white.withValues(alpha: 0.4),
            thumbColor: AppColors.playerSliderActive,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            min: 0,
            max: widget.max,
            value: widget.value,
            onChanged: widget.enabled ? widget.onSeek : null,
          ),
        ),
      ),
    );
  }
}
