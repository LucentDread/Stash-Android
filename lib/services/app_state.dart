import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/stash_client.dart';
import '../api/stash_repository.dart';
import '../models/scene_filter.dart';
import 'app_lock.dart';
import 'background_fetcher.dart';
import 'downloads.dart';
import 'scan_tracker.dart';

/// Holds the server configuration and the API repository built from it.
class AppState extends ChangeNotifier {
  AppState(this._prefs, {this._fetcher}) {
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
  static const _kPip = 'popup_player';
  static const _kHideRecents = 'hide_recents';
  static const _kAutoUpdate = 'auto_update';

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
      refreshData();
    }
  }

  void _use(StashRepository? repo) {
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

  /// Saved scene views (filter + sort), in display order.
  List<SavedView> get views {
    final raw = _prefs.getString(_kViews);
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

  SavedView? viewById(String? id) =>
      id == null ? null : views.where((v) => v.id == id).firstOrNull;

  /// Ids of the views making up the home page. Before 1.9 only one view
  /// could be chosen, under another key.
  List<String> get _homeIds {
    final ids = _prefs.getStringList(_kHomeViews);
    if (ids != null) return ids;
    final old = _prefs.getString(_kHomeView);
    return old == null ? [] : [old];
  }

  void _storeHomeIds(List<String> ids) {
    _prefs.setStringList(_kHomeViews, ids);
    _prefs.remove(_kHomeView);
  }

  /// The views stacked on the home page, in the order of [views]. Empty for
  /// the default dashboard.
  List<SavedView> get homeViews {
    final ids = _homeIds.toSet();
    return [
      for (final v in views)
        if (ids.contains(v.id)) v,
    ];
  }

  bool isHomeView(String id) => _homeIds.contains(id);

  /// Adds the view [id] to the home page, or removes it.
  void setHomeView(String id, bool onHome) {
    final ids = _homeIds..remove(id);
    if (onHome) ids.add(id);
    _storeHomeIds(ids);
    notifyListeners();
  }

  /// Back to the default dashboard.
  void clearHomeViews() {
    _storeHomeIds([]);
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
    _storeViews(views..removeWhere((v) => v.id == id));
  }

  void reorderViews(int oldIndex, int newIndex) {
    final list = views;
    list.insert(newIndex, list.removeAt(oldIndex));
    _storeViews(list);
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
