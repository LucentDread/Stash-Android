import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../api/stash_repository.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/downloads.dart';
import '../widgets/detail_widgets.dart';
import '../widgets/download_button.dart';
import '../widgets/net_image.dart';

/// Full-screen swipeable image viewer with pinch-to-zoom.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
    this.downloadable = true,
  });

  final List<StashImage> images;
  final int initialIndex;

  /// Offers to download and rate the image shown (not for offline
  /// copies).
  final bool downloadable;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _chrome = true;
  bool _zoomed = false;

  /// Image clips play without sound until asked.
  bool _muted = true;

  /// Ratings changed here, by image id (the images are not reloaded).
  final _ratings = <String, int?>{};

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  Widget _ratingBar(StashImage image) => ColoredBox(
    color: Colors.black45,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        // A row, not a Center: the bar must keep its own height.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LiveRating(
              key: ValueKey(image.id),
              initial: _ratings.containsKey(image.id)
                  ? _ratings[image.id]
                  : image.rating100,
              save: (r) async {
                await context.read<AppState>().repo!.rate(
                  EditKind.image,
                  image.id,
                  r,
                );
                _ratings[image.id] = r;
              },
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: _chrome && widget.downloadable
          ? _ratingBar(widget.images[_index])
          : null,
      appBar: _chrome
          ? AppBar(
              backgroundColor: Colors.black45,
              foregroundColor: Colors.white,
              title: Text('${_index + 1} / ${widget.images.length}'),
              actions: [
                if (widget.images[_index].isClip)
                  IconButton(
                    tooltip: _muted ? tr.soundOn : tr.soundOff,
                    icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                    onPressed: () => setState(() => _muted = !_muted),
                  ),
                if (widget.downloadable)
                  DownloadButton(
                    key: ValueKey(widget.images[_index].id),
                    kind: OfflineKind.image,
                    id: widget.images[_index].id,
                  ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _chrome = !_chrome),
        child: PageView.builder(
          controller: _controller,
          physics: _zoomed
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() {
            _index = i;
            _zoomed = false;
          }),
          itemBuilder: (_, i) => widget.images[i].isClip
              ? _ClipView(
                  image: widget.images[i],
                  active: i == _index,
                  muted: _muted,
                )
              : _ZoomableImage(
                  image: widget.images[i],
                  onZoomChanged: (z) {
                    if (z != _zoomed) setState(() => _zoomed = z);
                  },
                ),
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.image, required this.onZoomChanged});
  final StashImage image;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final _transform = TransformationController();
  TapDownDetails? _doubleTap;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed) {
      _transform.value = Matrix4.identity();
    } else {
      final p = _doubleTap?.localPosition ?? Offset.zero;
      _transform.value = Matrix4.identity()
        ..translateByDouble(-p.dx * 1.5, -p.dy * 1.5, 0, 1)
        ..scaleByDouble(2.5, 2.5, 1, 1);
    }
    widget.onZoomChanged(!zoomed);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _doubleTap = d,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transform,
        maxScale: 6,
        onInteractionEnd: (_) =>
            widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.01),
        child: SizedBox.expand(
          child: NetImage(
            widget.image.image ?? widget.image.preview,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// An image clip (a video file among the images), played in a loop while
/// it is the page shown.
class _ClipView extends StatefulWidget {
  const _ClipView({
    required this.image,
    required this.active,
    required this.muted,
  });
  final StashImage image;
  final bool active;
  final bool muted;

  @override
  State<_ClipView> createState() => _ClipViewState();
}

class _ClipViewState extends State<_ClipView> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final path = widget.image.image;
    if (path == null) return;
    final client = context.read<AppState>().client;
    final url = client?.mediaUrl(path);
    final c = path.startsWith('/')
        ? VideoPlayerController.file(File(path))
        : url == null
        ? null
        : VideoPlayerController.networkUrl(
            Uri.parse(url),
            httpHeaders: client!.authHeaders,
          );
    if (c == null) return;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(widget.muted ? 0 : 1);
      if (widget.active) await c.play();
    } catch (e) {
      await c.dispose();
      if (mounted) setState(() => _error = e);
      return;
    }
    if (!mounted) {
      await c.dispose();
      return;
    }
    setState(() => _controller = c);
  }

  @override
  void didUpdateWidget(_ClipView old) {
    super.didUpdateWidget(old);
    final c = _controller;
    if (c == null) return;
    if (old.muted != widget.muted) c.setVolume(widget.muted ? 0 : 1);
    if (old.active != widget.active) widget.active ? c.play() : c.pause();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) {
      // The clip's thumbnail meanwhile, or an error.
      return Stack(
        fit: StackFit.expand,
        children: [
          NetImage(widget.image.thumbnail, fit: BoxFit.contain),
          Center(
            child: _error != null
                ? Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 48,
                  )
                : const CircularProgressIndicator(),
          ),
        ],
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: VideoPlayer(c),
      ),
    );
  }
}
