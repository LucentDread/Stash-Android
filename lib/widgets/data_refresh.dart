import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

/// Lets a screen reload its data when [AppState.refreshData] is called
/// (e.g. after a library scan), wherever it sits in the navigation.
mixin DataRefresh<T extends StatefulWidget> on State<T> {
  int? _seenVersion;

  /// Call from `build`: runs [reload] after this frame when the server
  /// data changed since the previous build.
  void watchServerData(VoidCallback reload) {
    final version = context.select<AppState, int>((s) => s.dataVersion);
    if (_seenVersion != null && version != _seenVersion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) reload();
      });
    }
    _seenVersion = version;
  }
}
