import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// Optional password asked when the app starts, and when it comes back
/// after some time in the background.
///
/// Only a salted PBKDF2 hash of the password is stored.
class AppLock extends ChangeNotifier with WidgetsBindingObserver {
  AppLock(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _locked = enabled;
  }

  static const _kHash = 'lock_hash';
  static const _kSalt = 'lock_salt';
  static const _kDelay = 'lock_delay_minutes';
  static const _iterations = 20000;

  /// Choices for [delayMinutes]; null asks only when the app starts.
  static const delays = <int?>[0, 1, 5, 15, null];

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  bool get enabled => _prefs.getString(_kHash) != null;

  /// True while the lock screen must be shown.
  bool get locked => _locked;
  late bool _locked;

  /// Minutes spent in the background before the password is asked again,
  /// or null to ask only when the app starts.
  int? get delayMinutes {
    final v = _prefs.getInt(_kDelay) ?? 1;
    return v < 0 ? null : v;
  }

  set delayMinutes(int? v) {
    _prefs.setInt(_kDelay, v ?? -1);
    notifyListeners();
  }

  static String describeDelay(int? minutes) => switch (minutes) {
    null => tr.lockAtLaunchOnly,
    0 => tr.lockImmediately,
    _ => tr.lockAfterMinutes(minutes),
  };

  DateTime? _leftAt;

  bool check(String password) {
    final hash = _prefs.getString(_kHash);
    final salt = _prefs.getString(_kSalt);
    if (hash == null || salt == null) return true;
    return _hash(password, base64Decode(salt)) == hash;
  }

  /// Unlocks if [password] is right.
  bool unlock(String password) {
    if (!check(password)) return false;
    _locked = false;
    notifyListeners();
    return true;
  }

  /// Sets or replaces the password. The app stays unlocked.
  Future<void> setPassword(String password) async {
    final rnd = Random.secure();
    final salt = Uint8List.fromList([
      for (var i = 0; i < 16; i++) rnd.nextInt(256),
    ]);
    await _prefs.setString(_kSalt, base64Encode(salt));
    await _prefs.setString(_kHash, _hash(password, salt));
    notifyListeners();
  }

  Future<void> removePassword() async {
    await _prefs.remove(_kHash);
    await _prefs.remove(_kSalt);
    _locked = false;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      // "inactive" alone is not leaving: a system dialog, the notification
      // shade, or the video playing in a small window.
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        _leftAt ??= _clock();
      case AppLifecycleState.resumed:
        final left = _leftAt;
        _leftAt = null;
        final delay = delayMinutes;
        if (left != null &&
            enabled &&
            delay != null &&
            _clock().difference(left) >= Duration(minutes: delay)) {
          _locked = true;
          notifyListeners();
        }
      case _:
    }
  }

  /// PBKDF2-HMAC-SHA256 (one 32-byte block).
  static String _hash(String password, List<int> salt) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final out = List<int>.of(u);
    for (var i = 1; i < _iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return base64Encode(out);
  }
}
