import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/app_urls.dart';
import 'package:iptv_demo/constant/static_locale_data.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/model/channel_guide_model.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:iptv_demo/repositories/iptv_repository.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IptvController extends GetxController {
  static const int _listApiLimit = 10;
  /// Home "All" browse: request enough rows for every popular + active channel.
  static const int _homePopularFetchLimit = 10000;
  /// Search tab API page size (server pagination).
  static const int _searchApiPageSize = 20;
  static const int _favoritesPageSize = 10;
  static const String _searchAllStateKey = '__all__';
  static const String _prefsFavoriteIdsKey = 'favorite_channel_ids';
  static const String _prefsFavoriteSnapshotsKey = 'favorite_channel_snapshots';
  static const String _prefsLanguageKey = 'iptv_selected_language';
  static const String _prefsCountryKey = 'iptv_selected_country';

  late final IptvRepository _iptvRepository;

  // Observables
  var isLoading = true.obs;
  var categoryIds = <String>[AppStrings.all].obs;
  var allChannels = <IptvChannel>[].obs;
  /// Full channels-list API catalog for Search → All (not popular-only).
  var searchCatalogChannels = <IptvChannel>[].obs;
  final searchChannelsByCategory = <String, List<IptvChannel>>{}.obs;
  var searchFilteredChannels = <IptvChannel>[].obs;
  var isSearchCatalogLoading = false.obs;
  var isSearchPaginationLoading = false.obs;
  var favoritesVisibleChannels = <IptvChannel>[].obs;
  var isFavoritesPaginationLoading = false.obs;
  var filteredChannels = <IptvChannel>[].obs;
  var visibleChannels = <IptvChannel>[].obs;
  var isPaginationLoading = false.obs;

  var favoriteChannels = <String>[].obs;
  var favoriteChannelSnapshots = <String, IptvChannel>{}.obs;
  var currentlyPlayingChannel = Rxn<IptvChannel>();
  var isPlaying = false.obs;

  /// Home horizontal / list cards: `GET /guides/{id}` “now” row (one fetch per channel id).
  final RxMap<String, HomeGuideEntry> homeGuideEntryByChannelId =
      <String, HomeGuideEntry>{}.obs;

  var selectedLanguage = 'All'.obs;
  var selectedCountryCode = 'IN'.obs;

  /// API-backed languages shown in Settings → Language (falls back to static list).
  final availableLanguages = <LanguageItem>[].obs;
  final languageNameToCode = <String, String>{}.obs;

  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ScrollController homeCategoryScrollController = ScrollController();
  String lastHomeCategoryAutoScroll = '';
  String pendingHomeCategoryCenterId = '';

  int _currentIndex = 0;
  final int _pageSize = 10;
  final RxInt selectedIndex = 0.obs;
  int _apiPage = 1;
  int _totalPages = 1;
  String? _searchCatalogLocaleKey;
  final Map<String, _SearchCategoryLoadState> _searchLoadByCategory = {};
  String _activeSearchCategoryId = AppStrings.all;
  String _activeSearchQuery = '';
  int _favoritesVisibleIndex = 0;
  List<IptvChannel> _favoritesFilteredAll = [];

  RxString selectedCategory = AppStrings.all.obs;

  @override
  void onInit() {
    super.onInit();
    _iptvRepository = Get.find<IptvRepository>();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        unawaited(loadMore());
      }
    });

    unawaited(_startup());
  }

  /// Loads persisted favorites, then categories and channels from the API.
  Future<void> _startup() async {
    await _loadFavorites();
    await _loadRegionalPrefs();
    await fetchLanguages();
    await fetchCategories();
    await fetchChannels();
  }

  Future<void> _loadRegionalPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString(_prefsLanguageKey);
      if (lang != null && lang.isNotEmpty) {
        selectedLanguage.value = lang;
      } else {
        selectedLanguage.value = 'All';
      }
      final cc = prefs.getString(_prefsCountryKey);
      if (cc != null && cc.isNotEmpty) {
        selectedCountryCode.value = cc.toUpperCase();
      } else {
        selectedCountryCode.value = 'IN';
      }
    } catch (e) {
      debugPrint('[IptvController] load regional prefs: $e');
    }
  }

  Future<void> _persistLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsLanguageKey, selectedLanguage.value);
    } catch (e) {
      debugPrint('[IptvController] save language: $e');
    }
  }

  Future<void> _persistCountry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsCountryKey, selectedCountryCode.value);
    } catch (e) {
      debugPrint('[IptvController] save country: $e');
    }
  }

  Future<void> fetchLanguages() async {
    try {
      final response = await _iptvRepository.fetchLanguages(
        countryCode: selectedCountryCode.value,
      );
      if (response.statusCode != 200 || response.body.isEmpty) return;

      final parsedList = parseLanguagesFromApiBody(response.body);
      if (parsedList.isNotEmpty) {
        availableLanguages.assignAll(parsedList);
      }
      final parsedMap = parseLanguageCodeMapFromApiBody(response.body);
      if (parsedMap.isNotEmpty) {
        languageNameToCode.assignAll(parsedMap);
      }
    } catch (e) {
      debugPrint('[IptvController] fetch languages: $e');
    }
  }

  /// Query value for `language` on the channels API (`hin`, `eng`, …).
  String? _apiLanguageCode() {
    final selected = selectedLanguage.value.trim();
    if (selected.isNotEmpty && selected.toLowerCase() != 'all') {
      final mapped = languageNameToCode[selected];
      if (mapped != null && mapped.isNotEmpty) return mapped;
    }
    switch (selectedLanguage.value) {
      case 'Hindi':
        return 'hin';
      case 'English':
        return 'eng';
      default:
        return null;
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawIds = prefs.getString(_prefsFavoriteIdsKey);
      if (rawIds != null && rawIds.isNotEmpty) {
        final decoded = jsonDecode(rawIds);
        if (decoded is List) {
          favoriteChannels.assignAll(decoded.map((e) => e.toString()).toList());
        }
      }

      final rawSnapshots = prefs.getString(_prefsFavoriteSnapshotsKey);
      if (rawSnapshots == null || rawSnapshots.isEmpty) return;
      final decodedSnapshots = jsonDecode(rawSnapshots);
      if (decodedSnapshots is! Map) return;

      final snapshotMap = <String, IptvChannel>{};
      for (final entry in decodedSnapshots.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is! Map) continue;
        snapshotMap[key] =
            _channelFromSnapshotJson(Map<String, dynamic>.from(value));
      }

      favoriteChannelSnapshots.assignAll(snapshotMap);
      if (favoriteChannels.isEmpty) {
        favoriteChannels.assignAll(snapshotMap.keys.toList());
      } else {
        favoriteChannelSnapshots.removeWhere(
          (key, _) => !favoriteChannels.contains(key),
        );
      }
      _normalizeFavoriteKeys();
    } catch (e) {
      debugPrint('[IptvController] load favorites: $e');
    }
  }

  Future<void> _persistFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsFavoriteIdsKey,
        jsonEncode(favoriteChannels.toList()),
      );
      final snapshotsJson = <String, Map<String, dynamic>>{};
      for (final entry in favoriteChannelSnapshots.entries) {
        snapshotsJson[entry.key] = _channelToSnapshotJson(entry.value);
      }
      await prefs.setString(
        _prefsFavoriteSnapshotsKey,
        jsonEncode(snapshotsJson),
      );
    } catch (e) {
      debugPrint('[IptvController] save favorites: $e');
    }
  }

  /// Clears favorites from memory and SharedPreferences (e.g. on sign out).
  Future<void> clearFavorites() async {
    favoriteChannels.clear();
    favoriteChannelSnapshots.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsFavoriteIdsKey);
      await prefs.remove(_prefsFavoriteSnapshotsKey);
    } catch (e) {
      debugPrint('[IptvController] clear favorites: $e');
    }
  }

  Map<String, dynamic> _channelToSnapshotJson(IptvChannel channel) {
    return {
      'title': channel.title,
      'url': channel.url,
      'language': channel.language,
      'feedId': channel.feedId,
      'logo': channel.logo,
      'group': channel.group,
      'channelId': channel.channelId,
      'dbId': channel.dbId,
      'country': channel.country,
      'isActive': channel.isActive,
      'score': channel.score,
      'isPopular': channel.isPopular,
    };
  }

  IptvChannel _channelFromSnapshotJson(Map<String, dynamic> json) {
    return IptvChannel(
      title: _stringValue(json['title']),
      url: _stringValue(json['url']),
      language: _stringValue(json['language']),
      feedId: _stringValue(json['feedId']),
      logo: _stringValue(json['logo']),
      group: _stringValue(json['group']),
      channelId: _stringValue(json['channelId']),
      dbId: _stringValue(json['dbId']),
      country: _stringValue(json['country']),
      isActive: _isTruthy(json['isActive']),
      score: (json['score'] as num?)?.toInt() ?? 0,
      isPopular: _isTruthy(json['isPopular']),
    );
  }

  void _refreshFavoriteSnapshotsFromLoadedChannels() {
    if (favoriteChannels.isEmpty) return;
    final favoriteKeys = favoriteChannels.toSet();
    var changed = false;

    void refreshFrom(Iterable<IptvChannel> channels) {
      for (final channel in channels) {
        final key = channel.favoriteKey;
        if (!favoriteKeys.contains(key)) continue;
        final existing = favoriteChannelSnapshots[key];
        if (existing == null ||
            existing.title != channel.title ||
            existing.url != channel.url ||
            existing.language != channel.language ||
            existing.feedId != channel.feedId ||
            existing.logo != channel.logo ||
            existing.group != channel.group ||
            existing.channelId != channel.channelId ||
            existing.dbId != channel.dbId ||
            existing.country != channel.country ||
            existing.isActive != channel.isActive ||
            existing.score != channel.score ||
            existing.isPopular != channel.isPopular) {
          favoriteChannelSnapshots[key] = channel;
          changed = true;
        }
      }
    }

    refreshFrom(searchCatalogChannels);
    refreshFrom(allChannels);

    if (changed) {
      unawaited(_persistFavorites());
    }
  }

  bool _favoriteKeyMatchesChannel(String key, IptvChannel channel) {
    final k = key.trim();
    if (k.isEmpty) return false;
    if (k == channel.favoriteKey || k == channel.strictListDedupeKey) {
      return true;
    }

    final cid = channel.channelId.trim().toLowerCase();
    if (cid.isEmpty) {
      return channel.url.trim().isNotEmpty && k == channel.url.trim();
    }

    // Legacy: bare slug only (no ::) — do not match every feed for same channel_id.
    if (!k.contains('::') && !k.startsWith('id:') && !k.startsWith('name:')) {
      if (k == cid && channel.feedId.trim().isEmpty) return true;
    }

    // Legacy: channelId::feed without language.
    final feed = channel.feedId.trim().toLowerCase();
    if (feed.isNotEmpty) {
      if (k == '$cid::$feed' || k == 'id:$cid::$feed') return true;
    }

    if (channel.url.isNotEmpty && k == '$cid::${channel.url.trim()}') {
      return true;
    }
    return false;
  }

  void _normalizeFavoriteKeys() {
    if (favoriteChannels.isEmpty) return;
    final allKnown = <IptvChannel>[
      ...searchCatalogChannels,
      ...allChannels,
      ...favoriteChannelSnapshots.values,
    ];
    final normalized = <String>{};
    for (final key in favoriteChannels) {
      final match = allKnown.firstWhereOrNull(
        (channel) => _favoriteKeyMatchesChannel(key, channel),
      );
      normalized.add(match?.favoriteKey ?? key.trim());
    }

    if (normalized.length != favoriteChannels.length ||
        !normalized.containsAll(favoriteChannels)) {
      favoriteChannels.assignAll(normalized.where((k) => k.isNotEmpty));
      unawaited(_persistFavorites());
    }
  }

  String? _apiCategoryParam() {
    final normalized = selectedCategory.value.trim().toLowerCase();
    if (normalized.isEmpty || normalized == AppStrings.all.toLowerCase()) {
      return null;
    }
    return normalized;
  }

  Future<void> fetchCategories() async {
    try {
      final authService =
          Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
      final authHeaders = (authService != null &&
              authService.isLoggedIn.value &&
              authService.accessToken.value.isNotEmpty)
          ? authService.authHeaders
          : null;
      final response = await _iptvRepository.fetchCategories(
        countryCode: selectedCountryCode.value,
        language: _apiLanguageCode(),
        headers: authHeaders,
      );

      if (response.statusCode != 200 || response.body.isEmpty) {
        return;
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        return;
      }

      final raw = decoded['data'] as List<dynamic>? ?? [];
      final ids = <String>{};
      for (final item in raw) {
        final map =
            item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
        final id = ((map['id'] as String?) ??
                (map['category'] as String?) ??
                (map['name'] as String?) ??
                '')
            .trim()
            .toLowerCase();
        if (id.isNotEmpty) {
          ids.add(id);
        }
      }

      if (ids.isEmpty) {
        return;
      }

      final sortedIds = ids.toList()..sort();
      categoryIds.assignAll([AppStrings.all, ...sortedIds]);
    } catch (_) {
      // Keep default fallback list when categories API fails.
    }
  }

  String categoryLabel(String categoryId) {
    if (categoryId.toLowerCase() == AppStrings.all.toLowerCase()) {
      return AppStrings.all;
    }
    final words = categoryId
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (words.isEmpty) return categoryId;
    return words
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Uri _channelsUri(
    int page, {
    int? limit,
    String? language,
    String? country,
    bool popularOnly = false,
    bool skipHomeCategoryFilter = false,
    String? categoryOverride,
  }) {
    final params = <String, String>{
      'page': '$page',
      'limit': '${limit ?? _listApiLimit}',
      'is_active': 'true',
      'is_stream_url_working': 'true',
      'sortBy': 'score',
      'sort_by': 'score',
      'order': 'desc',
    };
    // Home "All": `is_popular=true` + `is_active=true` + working stream URL. Per-category: same filters minus popular.
    if (popularOnly) {
      params['is_popular'] = 'true';
    }
    if (categoryOverride != null && categoryOverride.trim().isNotEmpty) {
      params['category'] = categoryOverride.trim().toLowerCase();
    } else if (!skipHomeCategoryFilter) {
      final cat = _apiCategoryParam();
      if (cat != null) {
        params['category'] = cat;
      }
    }
    if (language != null && language.isNotEmpty) {
      params['language'] = language;
    }
    if (country != null && country.isNotEmpty) {
      params['country'] = country;
    }
    return Uri.parse(AppUrls.channelsList).replace(queryParameters: params);
  }

  String _stringValue(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    return raw.toString().trim();
  }

  bool _isTruthy(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final s = raw.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes' || s == 'success';
    }
    return false;
  }

  String _extractStreamUrl(Map<String, dynamic> json) {
    final directCandidates = [
      json['streams_url'],
      json['stream_url'],
      json['url'],
      json['streamUrl'],
      json['playback_url'],
      json['play_url'],
    ];
    for (final candidate in directCandidates) {
      final value = _stringValue(candidate);
      if (value.startsWith('http')) return value;
    }

    final stream = json['stream'];
    if (stream is Map) {
      final nestedUrl = _stringValue(stream['url'] ?? stream['stream_url']);
      if (nestedUrl.startsWith('http')) return nestedUrl;
    }

    final streams = json['streams'];
    if (streams is List && streams.isNotEmpty) {
      for (final item in streams) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final nestedUrl = _stringValue(map['url'] ?? map['stream_url']);
        if (nestedUrl.startsWith('http')) return nestedUrl;
      }
    }
    return '';
  }

  bool _parseIsActive(Map<String, dynamic> json) {
    final v = json['is_active'];
    if (v == null) return true;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return true;
  }

  IptvChannel _channelFromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final dbId = _stringValue(json['_id'] ?? json['id']);
    final slugId = _stringValue(json['channel_id'] ?? json['channelId']);
    final logo = _stringValue(
      json['logo'] ??
          json['logo_url'] ??
          json['logoUrl'] ??
          json['image'] ??
          json['thumbnail'],
    );
    final score = (json['score'] as num?)?.toInt() ?? 0;
    final isPopularRaw = json['is_popular'] ?? json['isPopular'];
    final isPopular = isPopularRaw == true ||
        isPopularRaw == 1 ||
        isPopularRaw?.toString().toLowerCase() == 'true';
    var language = _stringValue(json['language']);
    final langs = json['languages'];
    if (language.isEmpty && langs is List && langs.isNotEmpty) {
      language = _stringValue(langs.first);
    }
    final feedId = _stringValue(json['feed_id']).isNotEmpty
        ? _stringValue(json['feed_id'])
        : _stringValue(json['feedId']);
    return IptvChannel(
      title: json['name'] as String? ?? 'Unknown',
      url: _extractStreamUrl(json),
      language: language,
      feedId: feedId,
      logo: logo,
      group: cats.join(','),
      channelId: slugId,
      dbId: dbId,
      country: json['country'] as String? ?? '',
      isActive: _parseIsActive(json),
      score: score,
      isPopular: isPopular,
    );
  }

  ({List<IptvChannel> channels, int totalPages}) _parseListResponse(
    String body,
  ) {
    final decoded = json.decode(body) as Map<String, dynamic>;
    if (!_isTruthy(decoded['success'] ?? decoded['status'])) {
      return (channels: <IptvChannel>[], totalPages: 1);
    }
    final rawData = decoded['data'];
    final data = rawData is Map<String, dynamic> ? rawData : null;
    final raw = rawData is List
        ? rawData
        : (data?['channels'] as List<dynamic>? ??
            data?['items'] as List<dynamic>? ??
            <dynamic>[]);
    final channels = raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return _channelFromJson(m);
    }).toList();
    final pag = data?['pagination'] as Map<String, dynamic>?;
    final totalPages = (pag?['totalPages'] as num?)?.toInt() ?? 1;
    return (channels: channels, totalPages: totalPages);
  }

  /// Defensive filter: keep only rows eligible for home/search browse lists.
  /// This guarantees Home stays aligned with `is_active=true` even if backend
  /// accidentally returns inactive API channels.
  List<IptvChannel> _browseSafeChannels(List<IptvChannel> channels) {
    return channels.where((c) => c.showsInBrowseLists).toList();
  }

  String _searchCatalogLocaleKeyNow() =>
      '${selectedLanguage.value}|${selectedCountryCode.value}';

  void _invalidateSearchCatalog() {
    searchCatalogChannels.clear();
    searchChannelsByCategory.clear();
    searchFilteredChannels.clear();
    _searchLoadByCategory.clear();
    _searchCatalogLocaleKey = null;
  }

  String _searchStateKey(String categoryId) =>
      _isAllSearchCategory(categoryId)
          ? _searchAllStateKey
          : categoryId.trim().toLowerCase();

  void _syncChannelsFromLoadState(String categoryId) {
    final state = _searchLoadByCategory[_searchStateKey(categoryId)];
    if (state == null) return;
    final list = dedupeChannelsForSearchList(state.byKey.values.toList());
    if (_isAllSearchCategory(categoryId)) {
      searchCatalogChannels.assignAll(list);
    } else {
      searchChannelsByCategory[categoryId.trim().toLowerCase()] = list;
      searchChannelsByCategory.refresh();
    }
  }

  bool _channelMatchesSearchQuery(IptvChannel channel, String query) {
    if (query.isEmpty) return true;
    final title = channel.title.toLowerCase();
    final group = channel.group.toLowerCase();
    final country = channel.country.toLowerCase();
    return title.contains(query) ||
        group.contains(query) ||
        country.contains(query);
  }

  /// Rebuilds [searchFilteredChannels] from loaded API pages + query.
  void applySearchFilters({
    required String categoryId,
    required String query,
  }) {
    _activeSearchCategoryId = categoryId;
    _activeSearchQuery = query.trim().toLowerCase();
    final loaded = searchChannelsForCategory(categoryId);
    searchFilteredChannels.assignAll(
      dedupeChannelsForSearchList(
        loaded
            .where((c) => _channelMatchesSearchQuery(c, _activeSearchQuery))
            .toList(),
      ),
    );
  }

  bool get searchHasMore {
    final state = _searchLoadByCategory[_searchStateKey(_activeSearchCategoryId)];
    if (state == null) return false;
    return state.apiPage < state.totalPages;
  }

  Future<void> loadMoreSearch() async {
    if (isSearchPaginationLoading.value || !searchHasMore) return;
    isSearchPaginationLoading.value = true;
    try {
      await _fetchNextSearchPage(_activeSearchCategoryId);
      applySearchFilters(
        categoryId: _activeSearchCategoryId,
        query: _activeSearchQuery,
      );
    } finally {
      isSearchPaginationLoading.value = false;
    }
  }

  Future<bool> _fetchNextSearchPage(String categoryId) async {
    final stateKey = _searchStateKey(categoryId);
    var state = _searchLoadByCategory[stateKey];
    state ??= _searchLoadByCategory[stateKey] = _SearchCategoryLoadState();

    if (state.apiPage >= state.totalPages && state.apiPage > 0) {
      return false;
    }

    final nextPage = state.apiPage + 1;
    final uri = _channelsUri(
      nextPage,
      limit: _searchApiPageSize,
      language: _apiLanguageCode(),
      country: selectedCountryCode.value,
      popularOnly: false,
      skipHomeCategoryFilter: true,
      categoryOverride:
          _isAllSearchCategory(categoryId) ? null : stateKey,
    );
    final response = await _iptvRepository.fetchChannels(
      uri,
      debugTag: 'Channels API (search $stateKey p$nextPage)',
    );
    if (response.statusCode != 200 || response.body.isEmpty) return false;

    final parsed = _parseListResponse(response.body);
    _mergeSearchChannelsInto(
      state.byKey,
      _browseSafeChannels(parsed.channels),
    );
    state.apiPage = nextPage;
    state.totalPages = parsed.totalPages;
    _syncChannelsFromLoadState(categoryId);
    return true;
  }

  void applyFavoritesFilters({
    required String categoryId,
    required String query,
  }) {
    final searchQuery = query.trim().toLowerCase();
    var list = getFavoriteChannels();

    final selectedCategory = categoryId.trim().toLowerCase();
    if (selectedCategory != AppStrings.all.toLowerCase()) {
      list = list.where((channel) {
        final channelCategories = channel.group
            .toLowerCase()
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty);
        return channelCategories.contains(selectedCategory);
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      list = list
          .where(
            (channel) => channel.title.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    _favoritesFilteredAll = list;
    resetFavoritesPagination();
  }

  void resetFavoritesPagination() {
    _favoritesVisibleIndex = 0;
    favoritesVisibleChannels.assignAll(
      _favoritesFilteredAll.take(_favoritesPageSize),
    );
    _favoritesVisibleIndex = favoritesVisibleChannels.length;
  }

  Future<void> loadMoreFavorites() async {
    if (isFavoritesPaginationLoading.value) return;
    if (_favoritesVisibleIndex >= _favoritesFilteredAll.length) return;

    isFavoritesPaginationLoading.value = true;
    try {
      final next = _favoritesFilteredAll
          .skip(_favoritesVisibleIndex)
          .take(_favoritesPageSize)
          .toList();
      if (next.isEmpty) return;
      favoritesVisibleChannels.addAll(next);
      _favoritesVisibleIndex += next.length;
    } finally {
      isFavoritesPaginationLoading.value = false;
    }
  }

  bool get favoritesHasMore =>
      _favoritesVisibleIndex < _favoritesFilteredAll.length;

  List<IptvChannel> dedupeChannelsForSearchList(List<IptvChannel> channels) {
    if (channels.isEmpty) return const [];

    // One row per channel_id + feed_id (fixes API dupes with empty vs hin language).
    final byChannelFeed = <String, IptvChannel>{};
    for (final channel in channels) {
      final key = channel.channelFeedListDedupeKey;
      final existing = byChannelFeed[key];
      if (existing == null || channel.score > existing.score) {
        byChannelFeed[key] = channel;
      }
    }

    // Fallback: same title + feed when API uses different channel_id slugs.
    final byDisplay = <String, IptvChannel>{};
    for (final channel in byChannelFeed.values) {
      final key = channel.displayListDedupeKey;
      final existing = byDisplay[key];
      if (existing == null || channel.score > existing.score) {
        byDisplay[key] = channel;
      }
    }

    final list = byDisplay.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  /// Merges parsed API rows; one entry per [IptvChannel.channelFeedListDedupeKey].
  void _mergeSearchChannelsInto(
    Map<String, IptvChannel> target,
    Iterable<IptvChannel> channels,
  ) {
    for (final channel in channels) {
      final cfKey = channel.channelFeedListDedupeKey;
      IptvChannel? existing = target[cfKey];
      if (existing == null) {
        for (final entry in target.entries) {
          if (entry.value.displayListDedupeKey ==
              channel.displayListDedupeKey) {
            existing = entry.value;
            break;
          }
        }
      }
      if (existing == null || channel.score > existing.score) {
        if (existing != null) {
          target.remove(existing.channelFeedListDedupeKey);
        }
        target[cfKey] = channel;
      }
    }
  }

  bool _isAllSearchCategory(String categoryId) {
    final normalized = categoryId.trim().toLowerCase();
    return normalized.isEmpty || normalized == AppStrings.all.toLowerCase();
  }

  List<IptvChannel> searchChannelsForCategory(String categoryId) {
    if (_isAllSearchCategory(categoryId)) {
      return dedupeChannelsForSearchList(
        List<IptvChannel>.from(searchCatalogChannels),
      );
    }
    final key = categoryId.trim().toLowerCase();
    return dedupeChannelsForSearchList(
      List<IptvChannel>.from(searchChannelsByCategory[key] ?? const []),
    );
  }

  /// Search tab: loads first API page; scroll calls [loadMoreSearch] for next pages.
  Future<void> loadSearchChannelsForCategory(String categoryId) async {
    _activeSearchCategoryId = categoryId;
    final stateKey = _searchStateKey(categoryId);

    if ((_searchLoadByCategory[stateKey]?.apiPage ?? 0) > 0) {
      applySearchFilters(categoryId: categoryId, query: _activeSearchQuery);
      return;
    }
    if (isSearchCatalogLoading.value) return;

    isSearchCatalogLoading.value = true;
    try {
      _searchLoadByCategory[stateKey] = _SearchCategoryLoadState();
      await _fetchNextSearchPage(categoryId);
      if (_isAllSearchCategory(categoryId)) {
        _searchCatalogLocaleKey = _searchCatalogLocaleKeyNow();
        _refreshFavoriteSnapshotsFromLoadedChannels();
        _normalizeFavoriteKeys();
      }
      applySearchFilters(categoryId: categoryId, query: _activeSearchQuery);
    } catch (e) {
      debugPrint('[IptvController] search load $stateKey: $e');
    } finally {
      isSearchCatalogLoading.value = false;
    }
  }

  /// One section per channel (first known category token) to avoid duplicate rows.
  Map<String, List<IptvChannel>> groupSearchChannelsByCategory(
    List<IptvChannel> channels,
  ) {
    final grouped = <String, List<IptvChannel>>{};
    final allowedCategoryIds = categoryIds
        .map((id) => id.trim().toLowerCase())
        .where((id) => id.isNotEmpty && id != AppStrings.all.toLowerCase())
        .toSet();

    for (final channel in channels) {
      final tokens = channel.group
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      String label;
      if (tokens.isEmpty) {
        label = 'Other';
      } else {
        String? matchedToken;
        for (final token in tokens) {
          if (allowedCategoryIds.contains(token.toLowerCase())) {
            matchedToken = token;
            break;
          }
        }
        label = categoryLabel(matchedToken ?? tokens.first);
      }
      grouped.putIfAbsent(label, () => <IptvChannel>[]).add(channel);
    }
    return grouped.map(
      (label, list) => MapEntry(label, dedupeChannelsForSearchList(list)),
    );
  }

  /// Loads search “All” catalog (first page); use [loadSearchChannelsForCategory].
  Future<void> ensureSearchCatalogLoaded({bool force = false}) async {
    final localeKey = _searchCatalogLocaleKeyNow();
    if (force || _searchCatalogLocaleKey != localeKey) {
      _invalidateSearchCatalog();
    }
    if (!force &&
        _searchCatalogLocaleKey == localeKey &&
        (_searchLoadByCategory[_searchAllStateKey]?.apiPage ?? 0) > 0) {
      return;
    }
    await loadSearchChannelsForCategory(AppStrings.all);
  }

  /// Loads the first page for the current [selectedCategory] (uses `?category=` when not All).
  Future<void> fetchChannels({bool reset = true}) async {
    if (!reset) {
      await _fetchNextApiPage();
      return;
    }

    try {
      isLoading.value = true;
      _apiPage = 1;
      allChannels.clear();

      final isAllCategory = _apiCategoryParam() == null;
      final uri = _channelsUri(
        1,
        limit: isAllCategory ? _homePopularFetchLimit : _listApiLimit,
        language: _apiLanguageCode(),
        country: selectedCountryCode.value,
        popularOnly: isAllCategory,
      );
      final response = await _iptvRepository.fetchChannels(
        uri,
        debugTag: 'Channels API (initial)',
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final parsed = _parseListResponse(response.body);
        final safeChannels = _browseSafeChannels(parsed.channels);
        allChannels.assignAll(dedupeChannelsForSearchList(safeChannels));
        _refreshFavoriteSnapshotsFromLoadedChannels();
        _normalizeFavoriteKeys();
        _totalPages = parsed.totalPages;
        _apiPage = 1;
      } else {
        showAppToast(
          title: 'Error',
          message: 'Failed to load channels: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      showAppToast(
        title: 'Error',
        message: 'Could not load channels: ${e.toString()}',
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }

    applySearch(searchController.text, resetVisible: true);
  }

  Future<void> _fetchNextApiPage() async {
    if (_apiPage >= _totalPages) return;

    final nextPage = _apiPage + 1;
    final isAllCategory = _apiCategoryParam() == null;
    final uri = _channelsUri(
      nextPage,
      limit: isAllCategory ? _homePopularFetchLimit : _listApiLimit,
      language: _apiLanguageCode(),
      country: selectedCountryCode.value,
      popularOnly: isAllCategory,
    );
    final response = await _iptvRepository.fetchChannels(
      uri,
      debugTag: 'Channels API (pagination)',
    );

    if (response.statusCode != 200 || response.body.isEmpty) return;

    final parsed = _parseListResponse(response.body);
    allChannels.addAll(_browseSafeChannels(parsed.channels));
    allChannels.assignAll(dedupeChannelsForSearchList(allChannels));
    _refreshFavoriteSnapshotsFromLoadedChannels();
    _normalizeFavoriteKeys();
    _totalPages = parsed.totalPages;
    _apiPage = nextPage;
    applySearch(searchController.text, resetVisible: false);
  }

  void selectCategory(String category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
    unawaited(fetchChannels(reset: true));
  }

  /// Sort channels by score descending (highest score / most popular first).
  /// Used for single-category view and search results.
  List<IptvChannel> channelsSortedByTitle(List<IptvChannel> channels) {
    final list = List<IptvChannel>.from(channels);
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  /// Home horizontal rows: only channels with `is_popular` and `is_active` (browse-safe), score desc.
  List<IptvChannel> getPopularActiveHomeChannels(List<IptvChannel> channels) {
    final list = dedupeChannelsForSearchList(
      channels.where((c) => c.isPopular && c.showsInBrowseLists).toList(),
    );
    return list;
  }

  /// Homepage sections (All): every popular + active channel per category, sorted by score.
  Map<String, List<IptvChannel>> getHomeDisplayChannels([
    List<IptvChannel>? channels,
  ]) {
    final categories = categorizedChannels(channels);
    final homeCategories = <String, List<IptvChannel>>{};
    for (final entry in categories.entries) {
      if (entry.key == 'All') continue;
      homeCategories[entry.key] =
          getPopularActiveHomeChannels(entry.value);
    }
    return homeCategories;
  }

  void applySearch(String query, {bool resetVisible = true}) {
    final language = selectedLanguage.value;
    final browseChannels = _browseSafeChannels(allChannels);

    final List<IptvChannel> baseChannels;
    if (language == 'All') {
      baseChannels = List.from(browseChannels);
    } else {
      baseChannels = browseChannels
          .where((c) => _matchesLanguageFilter(c, language))
          .toList();
    }

    final q = query.toLowerCase();
    final List<IptvChannel> next;
    if (q.isEmpty) {
      next = List.from(baseChannels);
    } else {
      next =
          baseChannels.where((c) => c.title.toLowerCase().contains(q)).toList();
    }
    next.sort((a, b) => b.score.compareTo(a.score));
    filteredChannels.value = dedupeChannelsForSearchList(next);

    if (resetVisible) {
      resetPagination();
    }
  }

  void _appendVisibleFromFilteredSlice(int sliceLength) {
    if (sliceLength <= 0) return;
    final slice = filteredChannels
        .skip(_currentIndex)
        .take(sliceLength)
        .toList();
    if (slice.isEmpty) {
      _currentIndex += sliceLength;
      return;
    }

    final batch = dedupeChannelsForSearchList(slice);
    final seenChannelFeed =
        visibleChannels.map((c) => c.channelFeedListDedupeKey).toSet();
    final seenDisplay =
        visibleChannels.map((c) => c.displayListDedupeKey).toSet();
    for (final channel in batch) {
      final cfKey = channel.channelFeedListDedupeKey;
      final display = channel.displayListDedupeKey;
      if (seenChannelFeed.contains(cfKey) || seenDisplay.contains(display)) {
        continue;
      }
      seenChannelFeed.add(cfKey);
      seenDisplay.add(display);
      visibleChannels.add(channel);
    }
    _currentIndex += sliceLength;
    visibleChannels.assignAll(
      dedupeChannelsForSearchList(visibleChannels.toList()),
    );
  }

  bool _matchesLanguageFilter(IptvChannel channel, String selectedLanguage) {
    final lang = channel.language.trim().toLowerCase();
    if (lang.isEmpty) return true;

    switch (selectedLanguage) {
      case 'Hindi':
        return lang == 'hin' || lang == 'hindi';
      case 'English':
        return lang == 'eng' || lang == 'english';
      default:
        return true;
    }
  }

  void resetPagination() {
    _currentIndex = 0;
    visibleChannels.clear();
    _appendVisibleFromFilteredSlice(_pageSize);

    if (visibleChannels.isEmpty && _apiPage < _totalPages) {
      unawaited(loadMore());
    }
  }

  Future<void> loadMore() async {
    if (isPaginationLoading.value) return;
    isPaginationLoading.value = true;
    try {
      if (_currentIndex < filteredChannels.length) {
        _appendVisibleFromFilteredSlice(_pageSize);
        return;
      }

      if (_apiPage < _totalPages) {
        await _fetchNextApiPage();
        _appendVisibleFromFilteredSlice(_pageSize);
      }
    } finally {
      isPaginationLoading.value = false;
    }
  }

  bool get hasMoreVisibleChannels =>
      _currentIndex < filteredChannels.length || _apiPage < _totalPages;

  bool isFavoriteChannel(IptvChannel channel) {
    return favoriteChannels
        .any((key) => _favoriteKeyMatchesChannel(key, channel));
  }

  void toggleFavoriteChannel(IptvChannel channel) {
    final matchingKeys = favoriteChannels
        .where((key) => _favoriteKeyMatchesChannel(key, channel))
        .toList();
    if (matchingKeys.isNotEmpty) {
      favoriteChannels.removeWhere(
        (key) => _favoriteKeyMatchesChannel(key, channel),
      );
      favoriteChannelSnapshots.removeWhere(
        (key, value) => _favoriteKeyMatchesChannel(key, channel),
      );
    } else {
      final key = channel.favoriteKey;
      favoriteChannels.add(key);
      favoriteChannelSnapshots[key] = channel;
    }
    unawaited(_persistFavorites());
  }

  void playChannel(IptvChannel channel) {
    currentlyPlayingChannel.value = channel;
    isPlaying.value = true;
  }

  void togglePlayPause() {
    isPlaying.value = !isPlaying.value;
  }

  void stopPlaying() {
    currentlyPlayingChannel.value = null;
    isPlaying.value = false;
  }

  List<IptvChannel> getFavoriteChannels() {
    final favorites = <IptvChannel>[];
    final seen = <String>{};
    final allKnown = <IptvChannel>[
      ...searchCatalogChannels,
      ...allChannels,
      ...favoriteChannelSnapshots.values,
    ];
    for (final channel in allKnown) {
      final listKey = channel.channelFeedListDedupeKey;
      if (seen.contains(listKey)) continue;
      if (favoriteChannels
          .any((key) => _favoriteKeyMatchesChannel(key, channel))) {
        favorites.add(channel);
        seen.add(listKey);
      }
    }
    return dedupeChannelsForSearchList(favorites);
  }

  /// Lowercase ids from the categories API (excludes [AppStrings.all]).
  /// Empty means we did not get a usable list — home bucketing skips filtering.
  Set<String> _allowedCategoryIdsLower() {
    final out = <String>{};
    final allLower = AppStrings.all.toLowerCase();
    for (final id in categoryIds) {
      final n = id.trim().toLowerCase();
      if (n.isEmpty || n == allLower) continue;
      out.add(n);
    }
    return out;
  }

  /// Buckets API-backed rows using only `channel.group` (comma-separated API
  /// `categories`). If a channel has multiple categories, it appears in each
  /// bucket whose id is returned by the categories API (unknown tags are dropped).
  bool _bucketApiChannelForHome(
    Map<String, List<IptvChannel>> map,
    IptvChannel channel,
  ) {
    final tokens = channel.group
        .toLowerCase()
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    // If API categories are empty, keep this channel out of all home buckets.
    if (tokens.isEmpty) {
      return false;
    }

    final allowed = _allowedCategoryIdsLower();
    final useWhitelist = allowed.isNotEmpty;

    var added = false;
    for (final token in tokens) {
      if (useWhitelist && !allowed.contains(token)) {
        continue;
      }
      final displayCategory = categoryLabel(token);
      if (displayCategory.isEmpty) continue;
      map.putIfAbsent(displayCategory, () => <IptvChannel>[]);
      final bucket = map[displayCategory]!;
      final alreadyInBucket = bucket.any(
        (c) =>
            c.channelFeedListDedupeKey == channel.channelFeedListDedupeKey ||
            c.displayListDedupeKey == channel.displayListDedupeKey,
      );
      if (!alreadyInBucket) {
        bucket.add(channel);
      }
      added = true;
    }
    return added;
  }

  /// Groups API channels by comma-separated `categories` on each row.
  Map<String, List<IptvChannel>> categorizedChannels([
    List<IptvChannel>? channels,
  ]) {
    final map = <String, List<IptvChannel>>{'All': []};
    final channelsToProcess = _browseSafeChannels(channels ?? allChannels);

    for (final channel in channelsToProcess) {
      if (channel.channelId.isEmpty) {
        map['All']!.add(channel);
        continue;
      }
      final added = _bucketApiChannelForHome(map, channel);
      if (added) {
        final allBucket = map['All']!;
        final alreadyInAll = allBucket.any(
          (c) =>
              c.channelFeedListDedupeKey == channel.channelFeedListDedupeKey ||
              c.displayListDedupeKey == channel.displayListDedupeKey,
        );
        if (!alreadyInAll) {
          allBucket.add(channel);
        }
      }
    }
    return map.map(
      (key, list) => MapEntry(key, dedupeChannelsForSearchList(list)),
    );
  }

  String validUrl(String? url) {
    if (url == null || url.isEmpty || !url.startsWith('http')) {
      if (url != null && url.isNotEmpty && url.startsWith('/')) {
        return 'https://api.snapdockapp.com/iptv/$url';
      }
      return '';
    }
    try {
      final path = Uri.parse(url).path.toLowerCase();
      if (path.endsWith('.avif') ||
          path.endsWith('.heic') ||
          path.endsWith('.heif')) {
        return '';
      }
    } catch (_) {
      return '';
    }
    return url;
  }

  String getSubtitle(IptvChannel channel) {
    if (channel.feedIdLabel.isNotEmpty) {
      return channel.feedIdLabel;
    }
    final parts = <String>[];
    if (channel.country.isNotEmpty) {
      parts.add(channel.country);
    } else if (channel.group.isNotEmpty) {
      parts.add(channel.group);
    }
    if (parts.isNotEmpty) {
      return parts.join(' · ');
    }
    if (channel.title.toLowerCase().contains('news')) {
      return 'News';
    }
    if (channel.title.toLowerCase().contains('tv')) {
      return 'TV';
    }
    return 'Channel';
  }

  String getQuality(IptvChannel channel) {
    if (channel.title.contains('576')) return '576';
    return 'HD';
  }

  /// Persists language and refetches channels. Call from Settings → Language only.
  Future<void> setLanguageFilter(String language) async {
    if (selectedLanguage.value == language) return;
    selectedLanguage.value = language;
    _invalidateSearchCatalog();
    await _persistLanguage();
    await fetchCategories();
    final normalizedSelected = selectedCategory.value.trim().toLowerCase();
    final available = categoryIds.map((e) => e.toLowerCase()).toSet();
    if (!available.contains(normalizedSelected)) {
      selectedCategory.value = AppStrings.all;
    }
    await fetchChannels(reset: true);
    update();
  }

  /// Persists country and refetches channels. Call from Settings → Country only.
  Future<void> setCountryFilter(String countryCode) async {
    final nextCountry = countryCode.toUpperCase();
    if (selectedCountryCode.value == nextCountry) return;
    selectedCountryCode.value = nextCountry;
    _invalidateSearchCatalog();
    await _persistCountry();
    await fetchLanguages();
    await fetchCategories();
    final normalizedSelected = selectedCategory.value.trim().toLowerCase();
    final available = categoryIds.map((e) => e.toLowerCase()).toSet();
    if (!available.contains(normalizedSelected)) {
      selectedCategory.value = AppStrings.all;
    }
    await fetchChannels(reset: true);
    update();
  }

  /// Clears search and returns category to All without changing language or country
  /// (those are only changed from Settings and persisted there).
  void resetHomeBrowseFilters() {
    searchController.clear();
    final isAll =
        selectedCategory.value.toLowerCase() == AppStrings.all.toLowerCase();
    if (isAll) {
      applySearch('', resetVisible: true);
    } else {
      selectCategory(AppStrings.all);
    }
  }

  @override
  void onClose() {
    try {
      scrollController.dispose();
      homeCategoryScrollController.dispose();
      searchController.dispose();
    } catch (e) {
      debugPrint('Error disposing controllers: $e');
    }
    super.onClose();
  }

  Future<String?> fetchStreamUrl(String channelId) async {
    try {
      final infoResponse = await _iptvRepository.fetchChannelInfoForChannel(
        channelId,
      );
      if (infoResponse.statusCode == 200 && infoResponse.body.isNotEmpty) {
        final decoded = json.decode(infoResponse.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final data = decoded['data'];
          if (data is Map) {
            final infoUrl = _extractStreamUrl(Map<String, dynamic>.from(data));
            if (infoUrl.isNotEmpty) {
              return infoUrl;
            }
          }
        }
      }

      final response = await _iptvRepository.fetchStreamForChannel(channelId);

      if (response.statusCode != 200 || response.body.isEmpty) {
        return null;
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        return null;
      }

      final raw = decoded['data'] as List<dynamic>? ?? [];
      if (raw.isEmpty) {
        return null;
      }

      final streams =
          raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Prioritize HTTPS URLs to avoid mixed content issues or cleartext restrictions.
      final httpsStream = streams.firstWhereOrNull(
        (s) => (s['url'] as String? ?? '').startsWith('https'),
      );

      if (httpsStream != null) {
        return httpsStream['url'] as String?;
      }

      // Return the first available URL if no HTTPS found.
      return streams.first['url'] as String?;
    } catch (e) {
      debugPrint('Error fetching stream URL: $e');
      return null;
    }
  }

  /// Same id as channel schedule `GET /guides/{channelId}/{channelDbId}`.
  String guideLookupKey(IptvChannel channel) {
    final id = channel.streamChannelId;
    if (id.isNotEmpty) return id;
    return channel.feedId.trim();
  }

  /// Loads current program once per [guideLookupKey] for home UI (progress bar).
  Future<void> prefetchHomeGuideIfNeeded(IptvChannel channel) async {
    final key = guideLookupKey(channel);
    if (key.isEmpty) return;
    if (homeGuideEntryByChannelId.containsKey(key)) return;
    homeGuideEntryByChannelId[key] = const HomeGuideEntry(loading: true);
    try {
      Map<String, String>? headers;
      if (Get.isRegistered<AuthService>()) {
        final auth = Get.find<AuthService>();
        if (auth.isLoggedIn.value && auth.accessToken.value.isNotEmpty) {
          headers = auth.authHeaders;
        }
      }
      final dbId = channel.dbId.trim();
      if (dbId.isEmpty) {
        homeGuideEntryByChannelId[key] = const HomeGuideEntry(loading: false);
        return;
      }
      final data = await _iptvRepository.fetchChannelGuides(
        key,
        dbId,
        limit: 1,
        headers: headers,
      );
      homeGuideEntryByChannelId[key] =
          HomeGuideEntry(loading: false, current: data.current);
    } catch (e) {
      debugPrint('[IptvController] prefetchHomeGuideIfNeeded $key: $e');
      homeGuideEntryByChannelId[key] = const HomeGuideEntry(loading: false);
    }
  }
}

class _SearchCategoryLoadState {
  final Map<String, IptvChannel> byKey = {};
  int apiPage = 0;
  int totalPages = 1;
}
