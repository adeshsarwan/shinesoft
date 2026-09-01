import 'package:iptv_demo/ads/adsVariable.dart';

/// Shared helpers for inserting native/banner slots into scrollable lists.
class AdListUtils {
  AdListUtils._();

  static const int defaultInterval = 8;

  static bool isListAdSlot(int index, [int interval = defaultInterval]) {
    if (!AdsVariable.shouldShowAds) return false;
    return index != 0 && (index + 1) % (interval + 1) == 0;
  }

  static int contentIndexForListIndex(int index, [int interval = defaultInterval]) {
    if (!AdsVariable.shouldShowAds) return index;
    final adsBefore = (index + 1) ~/ (interval + 1);
    return index - adsBefore;
  }

  /// 0-based ad slot index for alternating native / banner creatives.
  static int adSlotNumber(int index, [int interval = defaultInterval]) {
    return (index + 1) ~/ (interval + 1) - 1;
  }
}
