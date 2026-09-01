import 'dart:async';

import 'package:iptv_demo/ads/tv_ad_policy.dart';
import 'package:iptv_demo/utils/post_auth_home_route.dart';

/// Chains AdMob `load()` calls so Android TV does not fire many requests at once
/// (which leads to error 3 "No fill" and error 1 throttling on leanback devices).
class AdLoadScheduler {
  AdLoadScheduler._();
  static final AdLoadScheduler instance = AdLoadScheduler._();

  Future<void> _chain = Future<void>.value();
  bool? _isTv;
  DateTime _nextSlotAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<bool> _tv() async {
    _isTv ??= await isAndroidTvLeanbackDevice();
    return _isTv!;
  }

  Duration _gapAfterRequest(bool isTv) =>
      isTv ? const Duration(seconds: 8) : const Duration(milliseconds: 900);

  /// Runs [startLoad] after prior queued loads and the minimum gap.
  Future<void> enqueue(Future<void> Function() startLoad) {
    final run = _chain.then((_) async {
      final isTv = await _tv();
      if (isTv) {
        final wait = TvAdPolicy.waitUntilReady();
        if (wait > Duration.zero) {
          await Future.delayed(wait);
        }
        if (!TvAdPolicy.canRequestNow) return;
      }

      final now = DateTime.now();
      if (now.isBefore(_nextSlotAt)) {
        await Future.delayed(_nextSlotAt.difference(now));
      }
      await startLoad();
      _nextSlotAt = DateTime.now().add(_gapAfterRequest(isTv));
    });
    _chain = run.catchError((_) {});
    return run;
  }

  /// Pushes back the next allowed load slot after a failed request.
  void deferNextSlot(Duration delay) {
    final candidate = DateTime.now().add(delay);
    if (candidate.isAfter(_nextSlotAt)) {
      _nextSlotAt = candidate;
    }
  }
}
