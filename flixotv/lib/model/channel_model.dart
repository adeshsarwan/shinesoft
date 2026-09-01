class IptvChannel {
  final String title;
  final String url;
  final String language;
  final String feedId;
  final String logo;
  final String group;

  /// IPTV channel id from API (e.g. `AndTV.in`); empty for playlist-sourced rows.
  final String channelId;

  /// Mongo `_id` from API — used for notifications and other id-based endpoints.
  final String dbId;
  final String country;

  /// From API `is_active`; when false the channel is hidden in browse lists. Defaults to true if omitted.
  final bool isActive;

  /// Score from API for ranking channels (higher is better)
  final int score;

  /// Whether this channel is marked as popular by the API
  final bool isPopular;

  IptvChannel({
    required this.title,
    required this.url,
    this.language = '',
    this.feedId = '',
    this.logo = '',
    this.group = '',
    this.channelId = '',
    this.dbId = '',
    this.country = '',
    this.isActive = true,
    this.score = 0,
    this.isPopular = false,
  });

  /// Slug used for stream/guide APIs; falls back to [dbId] when the API omits `channel_id`.
  String get streamChannelId =>
      channelId.trim().isNotEmpty ? channelId.trim() : dbId.trim();

  static final RegExp _mongoIdPattern = RegExp(r'^[a-f0-9]{24}$');

  /// ISO 639-2 / API language code for stable list deduplication.
  String get normalizedLanguageCode {
    final code = language.trim().toLowerCase();
    if (code.isEmpty) return '';
    const aliases = <String, String>{
      'hindi': 'hin',
      'english': 'eng',
      'tamil': 'tam',
      'telugu': 'tel',
      'malayalam': 'mal',
      'kannada': 'kan',
      'marathi': 'mar',
      'bengali': 'ben',
      'urdu': 'urd',
      'punjabi': 'pan',
      'gujarati': 'guj',
    };
    return aliases[code] ?? code;
  }

  String get _feedPartForDedupe {
    final feed = feedId.trim().toLowerCase();
    return feed.isEmpty ? '_' : feed;
  }

  String get _langPartForDedupe {
    final lang = normalizedLanguageCode;
    return lang.isEmpty ? '_' : lang;
  }

  /// Exact API `channel_id` + `feed_id` + `language` (case-insensitive).
  String get strictListDedupeKey {
    final cid = channelId.trim().toLowerCase();
    if (cid.isNotEmpty && !_mongoIdPattern.hasMatch(cid)) {
      return 'id:$cid::$_feedPartForDedupe::$_langPartForDedupe';
    }
    if (dbId.isNotEmpty) return 'db:$dbId';
    return displayListDedupeKey;
  }

  /// One visible row per `channel_id` + `feed_id` (language kept on the winner).
  String get channelFeedListDedupeKey {
    final cid = channelId.trim().toLowerCase();
    if (cid.isNotEmpty && !_mongoIdPattern.hasMatch(cid)) {
      return 'id:$cid::$_feedPartForDedupe';
    }
    if (dbId.isNotEmpty) return 'db:$dbId';
    return displayListDedupeKey;
  }

  /// Fallback when the API emits different `channel_id` values for the same name.
  String get displayListDedupeKey {
    final titleNorm =
        title.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return 'name:$titleNorm::$_feedPartForDedupe';
  }

  /// Used for visible-list guards during pagination.
  String get searchListDedupeKey => channelFeedListDedupeKey;

  /// Favorites: exact stream identity (channel + feed + language).
  String get favoriteKey => strictListDedupeKey;

  bool get isApiChannel => channelId.isNotEmpty;

  /// Home/search lists: API rows must be `is_active == true`.
  bool get showsInBrowseLists => !isApiChannel || isActive;

  /// Block opening the player for inactive API channels (e.g. from Favorites).
  bool get canOpenPlayer => !isApiChannel || isActive;

  String get _languageDisplay {
    final code = language.trim().toLowerCase();
    if (code.isEmpty) return '';
    const map = <String, String>{
      'eng': 'English',
      'hin': 'Hindi',
      'tam': 'Tamil',
      'tel': 'Telugu',
      'mal': 'Malayalam',
      'kan': 'Kannada',
      'mar': 'Marathi',
      'ben': 'Bengali',
      'urd': 'Urdu',
      'pan': 'Punjabi',
      'guj': 'Gujarati',
      'ara': 'Arabic',
      'fas': 'Persian',
      'spa': 'Spanish',
      'por': 'Portuguese',
      'fra': 'French',
      'aze': 'Azerbaijani',
      'tgl': 'Tagalog',
      'pus': 'Pashto',
      'gla': 'Scottish Gaelic',
      'prd': 'Parsi-Dari',
      'tuk': 'Turkmen',
    };
    return map[code] ?? (code[0].toUpperCase() + code.substring(1));
  }

  String get titleWithLanguage {
    final lang = _languageDisplay;
    if (lang.isEmpty) return title;
    return '$title [$lang]';
  }

  String get feedIdLabel {
    if (feedId.trim().isEmpty) return '';
    return feedId.trim();
  }
}
