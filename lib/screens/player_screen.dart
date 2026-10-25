import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../api/stash_client.dart';
import '../api/stash_repository.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import '../widgets/async_view.dart';

/// A playable source: the direct file or one of Stash's transcodes.
class _Source {
  const _Source(this.label, this.url, {this.hint});
  final String label;
  final String url;
  final VideoFormat? hint;
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.sceneId, this.startAt});
  final String sceneId;

  /// Start position in seconds; defaults to the saved resume position.
  final double? startAt;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const _seekStep = Duration(seconds: 10);

  late final AppState _app = context.read<AppState>();
  late final StashRepository _repo = _app.repo!;

  Scene? _scene;
  List<_Source> _sources = [];
  int _sourceIndex = 0;
  VideoPlayerController? _controller;
  Object? _error;

  bool _controlsVisible = true;
  Timer? _hideTimer;
  Timer? _activityTimer;
  Duration? _dragPosition;

  /// Seconds actually watched since the last activity save.
  double _unsavedPlay = 0;
  double _totalPlay = 0;
  Duration _lastPosition = Duration.zero;
  bool _playCounted = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _init();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _activityTimer?.cancel();
    _saveActivity(finalSave: true);
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _error = null);
    try {
      final scene = await _repo.findScene(widget.sceneId);
      List<StreamEndpoint> streams = const [];
      try {
        streams = await _repo.sceneStreams(widget.sceneId);
      } catch (_) {
        // Older servers: fall back to the direct stream only.
      }
      _scene = scene;
      _sources = _buildSources(scene, streams);
      if (_sources.isEmpty) throw StashException('Aucun flux disponible');

      final f = scene.file;
      if (f != null && f.width > 0 && f.height > 0) {
        SystemChrome.setPreferredOrientations(
          f.width >= f.height
              ? [
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]
              : [DeviceOrientation.portraitUp],
        );
      }

      var start = widget.startAt ?? scene.resumeTime ?? 0;
      if (scene.duration > 0 && start > scene.duration - 5) start = 0;
      await _open(
        0,
        Duration(milliseconds: (start * 1000).round()),
        fallback: true,
      );
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  List<_Source> _buildSources(Scene scene, List<StreamEndpoint> streams) {
    final client = _app.client!;
    final sources = <_Source>[];
    String? url(String? u) => client.mediaUrl(u);

    final direct = url(scene.stream);
    if (direct != null) sources.add(_Source('Direct (original)', direct));
    for (final s in streams) {
      final u = url(s.url);
      final mime = s.mimeType ?? '';
      if (u == null || u == direct) continue;
      if (s.label != null && s.label!.toLowerCase().contains('direct')) {
        continue;
      }
      // Transcoded MP4/WebM streams cannot seek in ExoPlayer; HLS and DASH
      // are segmented and seek fine, so keep those first.
      final hint = mime.contains('mpegurl')
          ? VideoFormat.hls
          : mime.contains('dash')
          ? VideoFormat.dash
          : null;
      sources.add(_Source(s.label ?? mime, u, hint: hint));
    }
    final segmented = sources.where((s) => s.hint != null).toList();
    final others = sources.where((s) => s.hint == null).toList();
    return [...others.take(1), ...segmented, ...others.skip(1)];
  }

  /// Opens source [index] at [position]. With [fallback], tries the next
  /// sources when the device cannot play this one (unsupported codec…).
  Future<void> _open(
    int index,
    Duration position, {
    bool fallback = false,
  }) async {
    final old = _controller;
    old?.removeListener(_onTick);
    setState(() {
      _controller = null;
      _sourceIndex = index;
      _error = null;
    });
    await old?.dispose();

    final source = _sources[index];
    final c = VideoPlayerController.networkUrl(
      Uri.parse(source.url),
      formatHint: source.hint,
      httpHeaders: _app.client!.authHeaders,
    );
    try {
      await c.initialize();
      if (position > Duration.zero) await c.seekTo(position);
      await c.play();
    } catch (e) {
      await c.dispose();
      if (fallback && index + 1 < _sources.length) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lecture directe impossible, essai de « ${_sources[index + 1].label} »',
              ),
            ),
          );
        }
        return _open(index + 1, position, fallback: true);
      }
      if (mounted) setState(() => _error = 'Lecture impossible : $e');
      return;
    }
    if (!mounted) {
      await c.dispose();
      return;
    }
    _lastPosition = c.value.position;
    c.addListener(_onTick);
    setState(() => _controller = c);
    _activityTimer ??= Timer.periodic(
      const Duration(seconds: 15),
      (_) => _saveActivity(),
    );
    _scheduleHide();
  }

  void _onTick() {
    final c = _controller;
    if (c == null) return;
    final pos = c.value.position;
    final delta = (pos - _lastPosition).inMilliseconds / 1000;
    // Count only continuous playback, not seeks.
    if (c.value.isPlaying && delta > 0 && delta < 2) {
      _unsavedPlay += delta;
      _totalPlay += delta;
      if (!_playCounted && _totalPlay >= 10) {
        _playCounted = true;
        _repo.addPlay(widget.sceneId).ignore();
      }
    }
    _lastPosition = pos;
    if (c.value.hasError && _error == null) {
      setState(() => _error = c.value.errorDescription ?? 'Erreur de lecture');
    }
    if (mounted) setState(() {});
  }

  void _saveActivity({bool finalSave = false}) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (_unsavedPlay <= 0 && !finalSave) return;
    final duration = c.value.duration.inMilliseconds / 1000;
    var resume = c.value.position.inMilliseconds / 1000;
    // Watched to the end: clear the resume point.
    if (duration > 0 && resume > duration * 0.98) resume = 0;
    final played = _unsavedPlay;
    _unsavedPlay = 0;
    _repo
        .saveActivity(
          widget.sceneId,
          resumeTime: resume,
          playDuration: played > 0 ? played : null,
        )
        .ignore();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    c.value.isPlaying ? c.pause() : c.play();
    _scheduleHide();
  }

  void _seekBy(Duration d) {
    final c = _controller;
    if (c == null) return;
    var target = c.value.position + d;
    if (target < Duration.zero) target = Duration.zero;
    if (target > c.value.duration) target = c.value.duration;
    c.seekTo(target);
    _scheduleHide();
  }

  void _seekTo(double seconds) {
    _controller?.seekTo(Duration(milliseconds: (seconds * 1000).round()));
    _scheduleHide();
  }

  Future<void> _pickSource() async {
    final i = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = 0; i < _sources.length; i++)
              ListTile(
                leading: Icon(
                  i == _sourceIndex
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(_sources[i].label),
                onTap: () => Navigator.pop(context, i),
              ),
          ],
        ),
      ),
    );
    if (i != null && i != _sourceIndex) {
      _saveActivity();
      await _open(i, _controller?.value.position ?? Duration.zero);
    }
  }

  Future<void> _pickSpeed() async {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final current = _controller?.value.playbackSpeed ?? 1;
    final s = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in speeds)
              ListTile(
                leading: Icon(
                  s == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text('×$s'),
                onTap: () => Navigator.pop(context, s),
              ),
          ],
        ),
      ),
    );
    if (s != null) await _controller?.setPlaybackSpeed(s);
  }

  Future<void> _pickMarker() async {
    final markers = _scene?.markers ?? const [];
    final m = await showModalBottomSheet<SceneMarker>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final m in markers)
              ListTile(
                leading: const Icon(Icons.bookmark_outline),
                title: Text(m.displayTitle),
                trailing: Text(formatDuration(m.seconds)),
                onTap: () => Navigator.pop(context, m),
              ),
          ],
        ),
      ),
    );
    if (m != null) _seekTo(m.seconds);
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null && c == null
          ? Theme(
              data: ThemeData.dark(),
              child: Stack(
                children: [
                  ErrorView(error: _error!, onRetry: _init),
                  SafeArea(child: BackButton(color: Colors.white)),
                ],
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: c == null
                      ? const CircularProgressIndicator()
                      : AspectRatio(
                          aspectRatio: c.value.aspectRatio,
                          child: VideoPlayer(c),
                        ),
                ),
                if (c != null && c.value.isBuffering)
                  const Center(child: CircularProgressIndicator()),
                _gestureLayer(),
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: _controls(c),
                  ),
                ),
              ],
            ),
    );
  }

  /// Tap toggles controls; double tap on either side seeks ±10 s.
  Widget _gestureLayer() {
    return Row(
      children: [
        for (final forward in [false, true])
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleControls,
              onDoubleTap: () => _seekBy(forward ? _seekStep : -_seekStep),
            ),
          ),
      ],
    );
  }

  Widget _controls(VideoPlayerController? c) {
    final value = c?.value;
    final duration = value?.duration ?? Duration.zero;
    final position = _dragPosition ?? value?.position ?? Duration.zero;
    final maxMs = duration.inMilliseconds.toDouble();
    final markers = _scene?.markers ?? const [];

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87,
            Colors.transparent,
            Colors.transparent,
            Colors.black87,
          ],
          stops: [0, 0.25, 0.7, 1],
        ),
      ),
      child: SafeArea(
        child: IconTheme(
          data: const IconThemeData(color: Colors.white),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: Column(
              children: [
                Row(
                  children: [
                    const BackButton(color: Colors.white),
                    Expanded(
                      child: Text(
                        _scene?.displayTitle ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (markers.isNotEmpty)
                      IconButton(
                        tooltip: 'Marqueurs',
                        icon: const Icon(Icons.bookmarks_outlined),
                        onPressed: _pickMarker,
                      ),
                    IconButton(
                      tooltip: 'Vitesse',
                      icon: const Icon(Icons.speed),
                      onPressed: _pickSpeed,
                    ),
                    if (_sources.length > 1)
                      IconButton(
                        tooltip: 'Flux',
                        icon: const Icon(Icons.high_quality_outlined),
                        onPressed: _pickSource,
                      ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.replay_10),
                      onPressed: () => _seekBy(-_seekStep),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      iconSize: 64,
                      icon: Icon(
                        value?.isPlaying ?? false
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                      ),
                      onPressed: _togglePlay,
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.forward_10),
                      onPressed: () => _seekBy(_seekStep),
                    ),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(formatDuration(position.inMilliseconds / 1000)),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (maxMs > 0)
                              Positioned.fill(
                                child: _MarkerTicks(
                                  markers: markers,
                                  durationSeconds: maxMs / 1000,
                                ),
                              ),
                            Slider(
                              value: position.inMilliseconds.toDouble().clamp(
                                0,
                                maxMs > 0 ? maxMs : 1,
                              ),
                              max: maxMs > 0 ? maxMs : 1,
                              onChangeStart: (_) => _hideTimer?.cancel(),
                              onChanged: maxMs <= 0
                                  ? null
                                  : (v) => setState(
                                      () => _dragPosition = Duration(
                                        milliseconds: v.round(),
                                      ),
                                    ),
                              onChangeEnd: (v) {
                                setState(() => _dragPosition = null);
                                _seekTo(v / 1000);
                              },
                            ),
                          ],
                        ),
                      ),
                      Text(formatDuration(duration.inMilliseconds / 1000)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small ticks drawn above the seek bar at each marker position.
class _MarkerTicks extends StatelessWidget {
  const _MarkerTicks({required this.markers, required this.durationSeconds});
  final List<SceneMarker> markers;
  final double durationSeconds;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Slider has a 24 px horizontal inset on each side.
        const inset = 24.0;
        final width = box.maxWidth - inset * 2;
        return Stack(
          children: [
            for (final m in markers)
              Positioned(
                left:
                    inset +
                    width * (m.seconds / durationSeconds).clamp(0, 1) -
                    1,
                top: box.maxHeight / 2 - 12,
                child: Container(width: 2, height: 8, color: Colors.amber),
              ),
          ],
        );
      },
    );
  }
}
