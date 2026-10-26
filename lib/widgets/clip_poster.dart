import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../api/stash_client.dart';
import '../services/app_state.dart';
import 'net_image.dart';

/// Preview of an image clip (a video among the images): its thumbnail when
/// Stash could make one, else the first frame of [video].
///
/// When Stash cannot make a clip's thumbnail it serves the clip itself in
/// its place; loaded as a picture, that whole video would only fail, and
/// fill the memory on the way. So the thumbnail is checked first.
class ClipPoster extends StatefulWidget {
  const ClipPoster({
    super.key,
    required this.thumbnail,
    required this.video,
    this.fit = BoxFit.cover,
  });

  /// Server URL or local file.
  final String? thumbnail;

  /// Video whose first frame stands in for a missing thumbnail (server URL
  /// or local file); none, nothing is shown then.
  final String? video;
  final BoxFit fit;

  @override
  State<ClipPoster> createState() => _ClipPosterState();
}

class _ClipPosterState extends State<ClipPoster> {
  bool _picture = false;
  VideoPlayerController? _frame;

  @override
  void initState() {
    super.initState();
    _choose();
  }

  Future<void> _choose() async {
    final client = context.read<AppState>().client;
    final thumb = widget.thumbnail;
    if (thumb != null && await _isPicture(thumb, client)) {
      if (mounted) setState(() => _picture = true);
      return;
    }
    final video = widget.video;
    if (!mounted || video == null) return;
    final local = video.startsWith('/');
    if (!local && client == null) return;
    final c = local
        ? VideoPlayerController.file(File(video))
        : VideoPlayerController.networkUrl(
            Uri.parse(client!.mediaUrl(video)!),
            httpHeaders: client.authHeaders,
          );
    try {
      await c.initialize();
      await c.setVolume(0);
    } catch (_) {
      await c.dispose();
      return;
    }
    if (!mounted) {
      await c.dispose();
      return;
    }
    setState(() => _frame = c);
  }

  Future<bool> _isPicture(String thumb, StashClient? client) async {
    if (!thumb.startsWith('/')) {
      return client == null || await client.isPicture(thumb);
    }
    // A local copy: look at its first bytes for a video container.
    try {
      final f = await File(thumb).open();
      final head = await f.read(12);
      await f.close();
      final isMp4 =
          head.length >= 8 &&
          String.fromCharCodes(head.sublist(4, 8)) == 'ftyp';
      final isWebm =
          head.length >= 4 &&
          head[0] == 0x1A &&
          head[1] == 0x45 &&
          head[2] == 0xDF &&
          head[3] == 0xA3;
      return !isMp4 && !isWebm;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _frame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_picture) {
      return NetImage(widget.thumbnail, fit: widget.fit, cacheWidth: 480);
    }
    final c = _frame;
    if (c == null) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    }
    return ClipRect(
      child: FittedBox(
        fit: widget.fit,
        child: SizedBox.fromSize(size: c.value.size, child: VideoPlayer(c)),
      ),
    );
  }
}
