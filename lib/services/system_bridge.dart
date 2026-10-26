import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';

/// Android features without a Flutter plugin, implemented in MainActivity:
/// black preview in recent apps, picture in picture, APK installation.
class SystemBridge {
  SystemBridge._() {
    _channel.setMethodCallHandler(_onCall);
  }

  static final instance = SystemBridge._();
  static const _channel = MethodChannel('stash/system');

  /// True while the activity is shown as a small window.
  final inPip = ValueNotifier<bool>(false);

  /// Called when the small window is closed (the activity is stopped).
  VoidCallback? onPipClosed;

  /// Called by the play/pause button of the small window.
  VoidCallback? onPipPlayPause;

  Future<void> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'pipChanged':
        final args = (call.arguments as Map).cast<String, Object?>();
        inPip.value = args['active'] == true;
        if (args['closed'] == true) onPipClosed?.call();
      case 'pipPlayPause':
        onPipPlayPause?.call();
    }
  }

  Future<void> _invoke(String method, [Object? args]) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Tests and other platforms.
    }
  }

  /// Writes the first frame of the video [source] (local file or URL) to
  /// [out] as a JPEG at most [width] pixels wide, without playing it.
  /// False when it could not.
  Future<bool> videoFrame({
    required String source,
    Map<String, String> headers = const {},
    required String out,
    int width = 320,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('videoFrame', {
            'source': source,
            'headers': headers,
            'out': out,
            'width': width,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Hides the app content in recent apps (and blocks screenshots).
  Future<void> setSecure(bool secure) => _invoke('setSecure', secure);

  /// Configures the small window: entered automatically when leaving the
  /// app while [enabled]. [width]/[height] give its shape.
  Future<void> setPip({
    required bool enabled,
    bool playing = false,
    int width = 16,
    int height = 9,
  }) => _invoke('setPip', {
    'enabled': enabled,
    'playing': playing,
    'width': width,
    'height': height,
    // The window's play/pause button, in the app's language.
    'playLabel': tr.play,
    'pauseLabel': tr.pause,
  });

  /// Opens the system installer for the APK at [path].
  Future<void> installApk(String path) => _invoke('installApk', path);
}
