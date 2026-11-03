import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../api/stash_client.dart';
import '../api/stash_repository.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/system_bridge.dart';
import '../utils/format.dart';
import '../widgets/async_view.dart';
import '../widgets/remote_keys.dart';
import 'edit/editors.dart';

/// A playable source: the direct file or one of Stash's transcodes.
class _Source {
  const _Source(this.label, this.url, {this.hint, this.local = false});
  final String label;
  final String url;
  final VideoFormat? hint;

  /// [url] is a file path on the phone (offline copy).
  final bool local;
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.sceneId,
    this.startAt,
    this.offlinePath,
    this.offlineData,
  });
  final String sceneId;

  /// Downloaded video and scene data: plays without the server and sends
  /// nothing back (no play count, no resume point).
  final String? offlinePath;
  final Map<String, dynamic>? offlineData;

  bool get offline => offlinePath != null;

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

  final _bridge = SystemBridge.instance;

  /// Remote control and keyboard: keys reach [_keys] while the controls
  /// are hidden; showing them puts the focus on play/pause.
  // Never reached by moving the focus, only given back (it covers the
  // whole page, so it would be "next to" every button).
  final _keys = FocusNode(debugLabel: 'player', skipTraversal: true);
  late final _playButton = _control('play');

  // The other controls, which the remote goes through row by row (see
  // [_controlRows]).
  late final _backButton = _control('back');
  late final _markersButton = _control('markers');
  late final _addMarkerButton = _control('add marker');
  late final _sourcesButton = _control('streams');
  late final _menuButton = _control('menu');
  late final _back10Button = _control('-10 s');
  late final _forward10Button = _control('+10 s');

  /// A control's focus node: it moves the focus itself with the arrows
  /// (before a widget around it, such as the menu's, does it its own way).
  FocusNode _control(String label) => FocusNode(
    debugLabel: label,
    onKeyEvent: (_, event) {
      if (event is KeyUpEvent) return KeyEventResult.ignored;
      if (!_moveFocus(event.logicalKey)) return KeyEventResult.ignored;
      _scheduleHide();
      return KeyEventResult.handled;
    },
  );

  /// The progress bar: Left/Right move it, Up/Down leave it.
  late final _sliderFocus = FocusNode(
    debugLabel: 'progress',
    onKeyEvent: (_, event) =>
        event is! KeyUpEvent &&
            (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) &&
            _moveFocus(event.logicalKey)
        ? KeyEventResult.handled
        : KeyEventResult.ignored,
  );
  final _menu = MenuController();

  /// Last state sent for the small window, to send only changes.
  String? _pipState;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _bridge.inPip.addListener(_onPipChanged);
    _bridge.onPipPlayPause = _togglePlay;
    // Closing the small window stops the video, as YouTube does.
    _bridge.onPipClosed = () => _controller?.pause();
    _init();
  }

  void _onPipChanged() {
    if (mounted) setState(() {});
  }

  /// Lets the video continue in a small window when leaving the app, while
  /// it plays and the setting allows it.
  void _updatePip() {
    final c = _controller;
    final enabled = _app.popupPlayer && c != null && c.value.isInitialized;
    final playing = c?.value.isPlaying ?? false;
    final size = c?.value.size ?? Size.zero;
    final w = size.width.round(), h = size.height.round();
    final state = '$enabled $playing $w $h';
    if (state == _pipState) return;
    _pipState = state;
    _bridge.setPip(
      enabled: enabled,
      playing: playing,
      width: w > 0 ? w : 16,
      height: h > 0 ? h : 9,
    );
  }

  @override
  void dispose() {
    _bridge.inPip.removeListener(_onPipChanged);
    if (_bridge.onPipPlayPause == _togglePlay) {
      _bridge.onPipPlayPause = null;
      _bridge.onPipClosed = null;
    }
    _bridge.setPip(enabled: false);
    _hideTimer?.cancel();
    _activityTimer?.cancel();
    _keys.dispose();
    for (final n in _controlNodes) {
      n.dispose();
    }
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
      final Scene scene;
      if (widget.offline) {
        scene = Scene.fromJson(widget.offlineData!);
        _sources = [_Source(tr.offlineCopy, widget.offlinePath!, local: true)];
      } else {
        scene = await _repo.findScene(widget.sceneId);
        List<StreamEndpoint> streams = const [];
        try {
          streams = await _repo.sceneStreams(widget.sceneId);
        } catch (_) {
          // Older servers: fall back to the direct stream only.
        }
        _sources = _buildSources(scene, streams);
      }
      _scene = scene;
      if (_sources.isEmpty) throw StashException(tr.noStream);

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
    if (direct != null) sources.add(_Source(tr.directStream, direct));
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
    final c = source.local
        ? VideoPlayerController.file(
            File(source.url),
            viewType: _bridge.videoViewType,
          )
        : VideoPlayerController.networkUrl(
            Uri.parse(source.url),
            formatHint: source.hint,
            httpHeaders: _app.client!.authHeaders,
            viewType: _bridge.videoViewType,
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
              content: Text(tr.directPlaybackFailed(_sources[index + 1].label)),
            ),
          );
        }
        return _open(index + 1, position, fallback: true);
      }
      if (mounted) setState(() => _error = tr.playbackFailed('$e'));
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
      if (!_playCounted && _totalPlay >= 10 && !widget.offline) {
        _playCounted = true;
        _repo.addPlay(widget.sceneId).ignore();
      }
    }
    _lastPosition = pos;
    _updatePip();
    if (c.value.hasError && _error == null) {
      setState(() => _error = c.value.errorDescription ?? tr.playbackError);
    }
    if (mounted) setState(() {});
  }

  void _saveActivity({bool finalSave = false}) {
    if (widget.offline) return;
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
        _hideControls();
      }
    });
  }

  void _hideControls() {
    // Not while the menu is open, nor under a sheet (streams, markers…):
    // taking the focus back would leave it.
    if (_menu.isOpen || !(ModalRoute.of(context)?.isCurrent ?? true)) {
      _scheduleHide();
      return;
    }
    setState(() => _controlsVisible = false);
    // Hidden buttons give up the focus: the keys come back here.
    _keys.requestFocus();
  }

  List<FocusNode> get _controlNodes => [
    _playButton,
    _backButton,
    _markersButton,
    _addMarkerButton,
    _sourcesButton,
    _menuButton,
    _back10Button,
    _forward10Button,
    _sliderFocus,
  ];

  /// The controls on screen, by row, left to right.
  List<List<FocusNode>> _controlRows() =>
      [
            [
              _backButton,
              _markersButton,
              _addMarkerButton,
              _sourcesButton,
              _menuButton,
            ],
            [_back10Button, _playButton, _forward10Button],
            [_sliderFocus],
          ]
          .map(
            (row) => row
                .where((n) => n.context != null && n.canRequestFocus)
                .toList(),
          )
          .where((row) => row.isNotEmpty)
          .toList();

  /// Moves the focus between the controls with an arrow: along a row, or
  /// to the nearest control of the row above or below. Stops at the edges
  /// (nothing else on the page can take the focus, e.g. the video). False
  /// when the focus is not on a control (e.g. in the menu).
  bool _moveFocus(LogicalKeyboardKey key) {
    final rows = _controlRows();
    final current = FocusManager.instance.primaryFocus;
    final r = rows.indexWhere((row) => row.contains(current));
    if (current == null || r < 0) return false;
    final c = rows[r].indexOf(current);
    FocusNode? target;
    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        target = c > 0 ? rows[r][c - 1] : null;
      case LogicalKeyboardKey.arrowRight:
        target = c + 1 < rows[r].length ? rows[r][c + 1] : null;
      case LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.arrowDown:
        final to = r + (key == LogicalKeyboardKey.arrowUp ? -1 : 1);
        if (to >= 0 && to < rows.length) {
          final x = current.rect.center.dx;
          target = rows[to].reduce(
            (a, b) =>
                (a.rect.center.dx - x).abs() <= (b.rect.center.dx - x).abs()
                ? a
                : b,
          );
        }
      default:
        return false;
    }
    target?.requestFocus();
    return true;
  }

  void _showControls({bool focusPlay = false}) {
    setState(() => _controlsVisible = true);
    if (focusPlay) {
      // Once the buttons can take the focus again (next frame).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controlsVisible) _playButton.requestFocus();
      });
    }
    _scheduleHide();
  }

  void _toggleControls() =>
      _controlsVisible ? _hideControls() : _showControls();

  /// Remote control: OK plays or pauses, Left/Right seek ±10 s, Up/Down
  /// show the controls; with the controls shown, the arrows move between
  /// the buttons. Media keys work at any time.
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final c = _controller;
    if (key == LogicalKeyboardKey.mediaPlayPause) {
      _togglePlay();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPlay) {
      c?.play();
      _scheduleHide();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPause ||
        key == LogicalKeyboardKey.mediaStop) {
      c?.pause();
      _showControls();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaFastForward ||
        key == LogicalKeyboardKey.mediaRewind) {
      _seekBy(
        key == LogicalKeyboardKey.mediaFastForward ? _seekStep : -_seekStep,
      );
      _showControls();
      return KeyEventResult.handled;
    }
    // Controls shown and a button focused: the arrows move between the
    // buttons, which stay up meanwhile. Shown without a focused button
    // (just opened): like hidden, the first key focuses play/pause.
    if (_controlsVisible && !_keys.hasPrimaryFocus) {
      _scheduleHide();
      return _moveFocus(key) ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    if (RemoteKeys.okKeys.contains(key)) {
      if (event is KeyDownEvent) _togglePlay();
      _showControls(focusPlay: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      _seekBy(key == LogicalKeyboardKey.arrowRight ? _seekStep : -_seekStep);
      _showControls(focusPlay: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      _showControls(focusPlay: true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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

  /// Pauses, opens the marker form at the current position, then refreshes
  /// the scene's markers.
  Future<void> _addMarker() async {
    final c = _controller!;
    final wasPlaying = c.value.isPlaying;
    await c.pause();
    _hideTimer?.cancel();
    if (!mounted) return;
    final created = await createMarker(
      context,
      widget.sceneId,
      at: c.value.position.inMilliseconds / 1000,
    );
    // The form may have shown the system bars (keyboard).
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (created) {
      try {
        final scene = await _repo.findScene(widget.sceneId);
        if (mounted) setState(() => _scene = scene);
      } catch (_) {
        // The marker exists; the list refreshes on the next opening.
      }
    }
    if (wasPlaying && mounted) await _controller?.play();
    _scheduleHide();
  }

  Future<void> _useFrameAsCover() async {
    final c = _controller;
    if (c == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.generateCover(
        widget.sceneId,
        c.value.position.inMilliseconds / 1000,
      );
      messenger.showSnackBar(SnackBar(content: Text(tr.coverGenerating)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
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
    if (_bridge.inPip.value) {
      // Small window: the video alone.
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: c == null
              ? null
              : AspectRatio(
                  aspectRatio: c.value.aspectRatio,
                  child: ExcludeFocus(child: VideoPlayer(c)),
                ),
        ),
      );
    }
    final page = Scaffold(
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
                          child: ExcludeFocus(child: VideoPlayer(c)),
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
                    child: ExcludeFocus(
                      excluding: !_controlsVisible,
                      child: _controls(c),
                    ),
                  ),
                ),
              ],
            ),
    );
    return Focus(
      focusNode: _keys,
      autofocus: true,
      onKeyEvent: _onKey,
      child: page,
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
                    IconButton(
                      focusNode: _backButton,
                      color: Colors.white,
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      icon: const BackButtonIcon(),
                      onPressed: () => Navigator.maybePop(context),
                    ),
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
                        focusNode: _markersButton,
                        tooltip: tr.markers,
                        icon: const Icon(Icons.bookmarks_outlined),
                        onPressed: _pickMarker,
                      ),
                    if (!widget.offline)
                      IconButton(
                        focusNode: _addMarkerButton,
                        tooltip: tr.addMarkerHere,
                        icon: const Icon(Icons.bookmark_add_outlined),
                        onPressed: c == null ? null : _addMarker,
                      ),
                    if (_sources.length > 1)
                      IconButton(
                        focusNode: _sourcesButton,
                        tooltip: tr.streams,
                        icon: const Icon(Icons.high_quality_outlined),
                        onPressed: _pickSource,
                      ),
                    MenuAnchor(
                      controller: _menu,
                      menuChildren: [
                        MenuItemButton(
                          leadingIcon: const Icon(Icons.speed),
                          onPressed: _pickSpeed,
                          child: Text(tr.playbackSpeed),
                        ),
                        if (!widget.offline)
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.wallpaper),
                            onPressed: _useFrameAsCover,
                            child: Text(tr.useFrameAsCover),
                          ),
                      ],
                      builder: (context, menu, _) => IconButton(
                        focusNode: _menuButton,
                        color: Colors.white,
                        tooltip: MaterialLocalizations.of(context)
                            .showMenuTooltip,
                        icon: const Icon(Icons.more_vert),
                        onPressed: () =>
                            menu.isOpen ? menu.close() : menu.open(),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      focusNode: _back10Button,
                      iconSize: 40,
                      icon: const Icon(Icons.replay_10),
                      onPressed: () => _seekBy(-_seekStep),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      focusNode: _playButton,
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
                      focusNode: _forward10Button,
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
                              focusNode: _sliderFocus,
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
