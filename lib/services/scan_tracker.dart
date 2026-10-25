import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'app_state.dart';

enum ScanPhase { idle, running, finished, failed }

/// Starts a library scan and follows its progress by polling the job.
/// When the job ends, the app's data is refreshed.
class ScanTracker extends ChangeNotifier {
  ScanTracker(
    this._app, {
    this.pollInterval = const Duration(seconds: 1),
    this.doneDisplay = const Duration(seconds: 4),
  });

  final AppState _app;
  final Duration pollInterval;

  /// How long the "finished" message stays visible.
  final Duration doneDisplay;

  ScanPhase phase = ScanPhase.idle;
  String? jobId;
  Job? job;
  String? error;
  Timer? _poll;
  Timer? _hide;

  bool get running => phase == ScanPhase.running;

  /// Current file without Stash's "Scanning " prefix.
  String? get currentItem {
    final tasks = job?.subTasks ?? const [];
    if (tasks.isEmpty) return null;
    final t = tasks.last;
    return t.startsWith('Scanning ') ? t.substring('Scanning '.length) : t;
  }

  Future<void> start() async {
    if (running) return;
    _hide?.cancel();
    final repo = _app.repo;
    if (repo == null) return;
    phase = ScanPhase.running;
    job = null;
    error = null;
    notifyListeners();
    try {
      jobId = await repo.startScan();
    } catch (e) {
      _finish(ScanPhase.failed, e.toString());
      return;
    }
    _poll = Timer.periodic(pollInterval, (_) => _check());
    await _check();
  }

  Future<void> stop() async {
    final id = jobId;
    if (id == null || !running) return;
    try {
      await _app.repo?.stopJob(id);
    } catch (_) {
      // The next poll reports the job's real state.
    }
  }

  bool _checking = false;

  Future<void> _check() async {
    final id = jobId;
    final repo = _app.repo;
    if (id == null || repo == null || _checking || !running) return;
    _checking = true;
    try {
      final j = await repo.findJob(id);
      if (!running) return;
      // Stash drops finished jobs after a while: null means done.
      if (j == null) {
        _finish(ScanPhase.finished, null);
      } else {
        job = j;
        if (j.isDone) {
          _finish(
            j.status == 'FAILED' ? ScanPhase.failed : ScanPhase.finished,
            j.error,
          );
        } else {
          notifyListeners();
        }
      }
    } catch (_) {
      // Transient network error: keep polling.
    } finally {
      _checking = false;
    }
  }

  void _finish(ScanPhase result, String? message) {
    _poll?.cancel();
    phase = result;
    error = message;
    notifyListeners();
    if (result == ScanPhase.finished) _app.refreshData();
    _hide = Timer(doneDisplay, dismiss);
  }

  void dismiss() {
    _hide?.cancel();
    if (running) return;
    phase = ScanPhase.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _hide?.cancel();
    super.dispose();
  }
}
