import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/stash_client.dart';
import '../api/stash_repository.dart';
import '../l10n/l10n.dart';
import '../models/home_section.dart';
import '../models/scene_filter.dart';
import 'app_lock.dart';
import 'background_fetcher.dart';
import 'downloads.dart';
import 'scan_tracker.dart';

/// Holds the server configuration and the API repository built from it.
class AppState extends ChangeNotifier {
  AppState(this._prefs, {this._fetcher}) {
    _applyLanguage();
    final url = _prefs.getString(_kUrl);
    if (url != null && url.isNotEmpty) {
      _connect(url, _prefs.getString(_kKey));
    }
  }

  static const _kUrl = 'server_url';
  static const _kKey = 'api_key';
  static const _kColumns = 'grid_columns';
  static const _kPreview = 'play_previews';
  static const _kViews = 'saved_views';
  static const _kHomeView = 'home_view';
  static const _kHomeViews = 'home_views';
  static const _kHomeLayout = 'home_layout';
  static const _kDashboardLayout = 'dashboard_layout';
  static const _kWebViews = 'web_views';
  static const _kViewOrder = 'view_order';
  static const _kPip = 'popup_player';
  static const _kHideRecents = 'hide_recents';
  static const _kAutoUpdate = 'auto_update';
  static const _kTabs = 'tabs';
  static const _kLanguage = 'language';

  final SharedPreferences _prefs;
  StashRepository? _repo;

  /// Library scan started from the app, shown in a banner on every page.
  late final ScanTracker scan = ScanTracker(this);

  final FileFetcher? _fetcher;

  /// Optional password protecting the app.
  late final AppLock lock = AppLock(_prefs);

  /// Scenes, groups and galleries kept for offline viewing.
  late final DownloadManager downloads = DownloadManager(
    this,
    _fetcher ?? BackgroundFetcher(),
  );

  /// True while the Stash server cannot be reached.
  bool get offline => _offline;
  bool _offline = false;
  Timer? _probe;

  void _onReachability(bool reachable) {
    if (reachable != _offline) return;
    _offline = !reachable;
    notifyListeners();
    if (_offline) {
      // Nothing else may hit the server meanwhile: check it regularly.
      _probe = Timer.periodic(const Duration(seconds: 20), (_) {
        _repo?.version().ignore();
      });
    } else {
      _probe?.cancel();
      _serverVersion = null; // may have failed while offline
      refreshData();
    }
  }

  /// Version reported by the server, asked once per connection (pages
  /// rebuilding would otherwise start new requests, whose errors nobody
  /// listens to).
  Future<String>? get serverVersion =>
      _serverVersion ??= _repo?.version()?..ignore();
  Future<String>? _serverVersion;

  void _use(StashRepository? repo) {
    _serverVersion = null;
    _repo?.client.onReachability = null;
    _repo = repo;
    repo?.client.onReachability = _onReachability;
    if (repo == null && _offline) {
      _offline = false;
      _probe?.cancel();
    }
  }

  StashRepository? get repo => _repo;

  /// Incremented when server data changed outside the current screens
  /// (e.g. after a library scan). Lists and detail pages watch it and
  /// reload in place, without changing the navigation.
  int get dataVersion => _dataVersion;
  int _dataVersion = 0;

  void refreshData() {
    _dataVersion++;
    notifyListeners();
  }

  @visibleForTesting
  set repoOverride(StashRepository repo) {
    _use(repo);
    notifyListeners();
  }

  StashClient? get client => _repo?.client;
  bool get isConfigured => _repo != null;
  String? get serverUrl => _prefs.getString(_kUrl);
  String? get apiKey => _prefs.getString(_kKey);

  /// Language chosen in the settings, or null to follow the device.
  String? get language => _prefs.getString(_kLanguage);
  set language(String? v) {
    v == null ? _prefs.remove(_kLanguage) : _prefs.setString(_kLanguage, v);
    _applyLanguage();
    notifyListeners();
  }

  /// The language the app speaks.
  String get effectiveLanguage {
    final l = language;
    return l != null && appLanguages.contains(l) ? l : systemLanguage();
  }

  void _applyLanguage() =>
      tr = lookupAppLocalizations(Locale(effectiveLanguage));

  /// Number of columns used by scene grids in portrait mode.
  int get gridColumns => _prefs.getInt(_kColumns) ?? 2;
  set gridColumns(int v) {
    _prefs.setInt(_kColumns, v);
    notifyListeners();
  }

  /// Whether scene cards play their preview clip when long-pressed.
  bool get playPreviews => _prefs.getBool(_kPreview) ?? true;
  set playPreviews(bool v) {
    _prefs.setBool(_kPreview, v);
    notifyListeners();
  }

  /// Views made in the app (filter + sort), in creation order.
  List<SavedView> get views => _readViews(_kViews);

  /// Filters saved in Stash's web UI, as last read from the server.
  List<SavedView> get webViews => _readViews(_kWebViews);

  List<SavedView> _readViews(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return [
        for (final v in jsonDecode(raw) as List)
          SavedView.fromJson((v as Map).cast<String, dynamic>()),
      ];
    } catch (_) {
      return [];
    }
  }

  /// App views and web UI filters together, in the order chosen in
  /// Plus > Vues enregistrées (new ones last).
  List<SavedView> get allViews {
    final all = [...views, ...webViews];
    final order = _prefs.getStringList(_kViewOrder) ?? const [];
    final index = {for (var i = 0; i < all.length; i++) all[i].id: i};
    int rank(SavedView v) {
      final i = order.indexOf(v.id);
      return i < 0 ? order.length + index[v.id]! : i;
    }

    return all..sort((a, b) => rank(a).compareTo(rank(b)));
  }

  SavedView? viewById(String? id) =>
      id == null ? null : allViews.where((v) => v.id == id).firstOrNull;

  /// Reads the filters saved in the web UI again. Returns how many could
  /// not be used (image lists).
  Future<int> refreshWebViews() async {
    final repo = _repo;
    if (repo == null) return 0;
    final raw = await repo.savedFilters();
    final list = [for (final f in raw) ?SavedView.fromServer(f)];
    _prefs.setString(
      _kWebViews,
      jsonEncode([for (final v in list) v.toJson()]),
    );
    notifyListeners();
    return raw.length - list.length;
  }

  /// The custom home page as stored: view ids and [HomeSection] ids, in
  /// order. Ids of views not loaded yet (web filters) are kept.
  List<String> get _homeIds {
    final ids = _prefs.getStringList(_kHomeLayout);
    if (ids != null) return ids;
    // Before 1.12: views only, in the order of the views list; before 1.9
    // a single view, under another key.
    final old = {
      ...?_prefs.getStringList(_kHomeViews),
      ?_prefs.getString(_kHomeView),
    };
    return [
      for (final v in allViews)
        if (old.contains(v.id)) v.id,
    ];
  }

  void _storeHomeIds(List<String> ids) {
    _prefs.setStringList(_kHomeLayout, ids);
    // Replaced by the layout.
    _prefs.remove(_kHomeViews);
    _prefs.remove(_kHomeView);
    notifyListeners();
  }

  /// Ids that still name a view or a section.
  List<String> _existing(List<String> ids) {
    final views = {for (final v in allViews) v.id};
    return [
      for (final id in ids)
        if (views.contains(id) || HomeSection.fromId(id) != null) id,
    ];
  }

  /// The custom home page: views and dashboard sections, stacked in this
  /// order. Empty for the default dashboard.
  List<String> get homeLayout => _existing(_homeIds);
  set homeLayout(List<String> ids) => _storeHomeIds(ids);

  /// The views of the custom home page.
  List<SavedView> get homeViews => [for (final id in homeLayout) ?viewById(id)];

  bool isHomeView(String id) => _homeIds.contains(id);

  /// Adds the view [id] at the end of the home page, or removes it.
  void setHomeView(String id, bool onHome) {
    final ids = _homeIds..remove(id);
    if (onHome) ids.add(id);
    _storeHomeIds(ids);
  }

  /// Back to the default dashboard.
  void clearHomeViews() => _storeHomeIds([]);

  /// Rows of the default dashboard, in order: sections and views. Until
  /// chosen, the sections with the app's views after "Reprendre la
  /// lecture", as before 1.12.
  List<String> get dashboardLayout => _existing(
    _prefs.getStringList(_kDashboardLayout) ??
        [
          HomeSection.stats.id,
          HomeSection.resume.id,
          for (final v in views) v.id,
          for (final s in HomeSection.values.skip(2)) s.id,
        ],
  );

  /// Null goes back to the default rows.
  set dashboardLayout(List<String>? ids) {
    if (ids == null) {
      _prefs.remove(_kDashboardLayout);
    } else {
      _prefs.setStringList(_kDashboardLayout, ids);
    }
    notifyListeners();
  }

  /// Names of the screens chosen as bottom bar tabs (see AppScreen), or
  /// null for the default bar.
  List<String>? get tabNames => _prefs.getStringList(_kTabs);
  set tabNames(List<String>? v) {
    if (v == null) {
      _prefs.remove(_kTabs);
    } else {
      _prefs.setStringList(_kTabs, v);
    }
    notifyListeners();
  }

  /// Whether a playing video continues in a small window (picture in
  /// picture) when leaving the app.
  bool get popupPlayer => _prefs.getBool(_kPip) ?? true;
  set popupPlayer(bool v) {
    _prefs.setBool(_kPip, v);
    notifyListeners();
  }

  /// Black preview in the recent apps screen (also blocks screenshots).
  /// Read natively too, at startup (MainActivity).
  bool get hideInRecents => _prefs.getBool(_kHideRecents) ?? true;
  set hideInRecents(bool v) {
    _prefs.setBool(_kHideRecents, v);
    notifyListeners();
  }

  /// Whether a new release is looked for when the app starts.
  bool get autoUpdate => _prefs.getBool(_kAutoUpdate) ?? true;
  set autoUpdate(bool v) {
    _prefs.setBool(_kAutoUpdate, v);
    notifyListeners();
  }

  SharedPreferences get prefs => _prefs;

  /// Adds [view], or replaces the view with the same id.
  void saveView(SavedView view) {
    final list = views;
    final i = list.indexWhere((v) => v.id == view.id);
    if (i >= 0) {
      list[i] = view;
    } else {
      list.add(view);
    }
    _storeViews(list);
  }

  void deleteView(String id) {
    if (_homeIds.contains(id)) _storeHomeIds(_homeIds..remove(id));
    final rows = _prefs.getStringList(_kDashboardLayout);
    if (rows != null && rows.remove(id)) {
      _prefs.setStringList(_kDashboardLayout, rows);
    }
    _storeViews(views..removeWhere((v) => v.id == id));
  }

  /// Moves a view within [allViews].
  void reorderViews(int oldIndex, int newIndex) {
    final list = allViews;
    list.insert(newIndex, list.removeAt(oldIndex));
    _prefs.setStringList(_kViewOrder, [for (final v in list) v.id]);
    notifyListeners();
  }

  void _storeViews(List<SavedView> list) {
    _prefs.setString(_kViews, jsonEncode([for (final v in list) v.toJson()]));
    notifyListeners();
  }

  /// Checks the server answers, then saves the configuration.
  /// Returns the Stash version reported by the server.
  Future<String> configure(String url, String? apiKey) async {
    final client = StashClient(serverUrl: url, apiKey: apiKey);
    final repo = StashRepository(client);
    final version = await repo.version();
    if (client.serverUrl != serverUrl) await _prefs.remove(_kWebViews);
    await _prefs.setString(_kUrl, client.serverUrl);
    if (client.apiKey == null) {
      await _prefs.remove(_kKey);
    } else {
      await _prefs.setString(_kKey, client.apiKey!);
    }
    _repo?.client.close();
    _use(repo);
    notifyListeners();
    return version;
  }

  Future<void> disconnect() async {
    // The web UI filters belong to that server.
    await _prefs.remove(_kWebViews);
    await _prefs.remove(_kUrl);
    await _prefs.remove(_kKey);
    _repo?.client.close();
    _use(null);
    notifyListeners();
  }

  void _connect(String url, String? key) {
    _use(StashRepository(StashClient(serverUrl: url, apiKey: key)));
  }
}
