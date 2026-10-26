import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../api/stash_client.dart';
import '../services/app_state.dart';
import '../services/system_bridge.dart';
import 'net_image.dart';

/// Preview of an image clip (a video among the images): its thumbnail when
/// Stash could make one, else a frame of [video].
///
/// When Stash cannot make a clip's thumbnail it serves the clip itself in
/// its place; loaded as a picture, that whole video would only fail, and
/// fill the memory on the way. So the thumbnail is checked first. Frames
/// are taken once, natively and without a player (a grid may show dozens
/// of clips; video decoders are few), and kept as small pictures.
class ClipPoster extends StatefulWidget {
  const ClipPoster({
    super.key,
    required this.thumbnail,
    required this.video,
    this.fit = BoxFit.cover,
    this.cacheWidth = 480,
  });

  /// Server URL or local file.
  final String? thumbnail;

  /// Video whose first frame stands in for a missing thumbnail (server URL
  /// or local file); none, nothing is shown then.
  final String? video;
  final BoxFit fit;
  final int cacheWidth;

  /// Where frames are kept (a cache the system may clear).
  @visibleForTesting
  static Future<String> Function() frameDir = () async =>
      '${(await getTemporaryDirectory()).path}/clip_frames';

  /// Frames being taken, by file: each is taken once.
  static final _taking = <String, Future<bool>>{};

  @override
  State<ClipPoster> createState() => _ClipPosterState();
}

class _ClipPosterState extends State<ClipPoster> {
  /// What to show: the thumbnail or a frame file.
  String? _shown;

  @override
  void initState() {
    super.initState();
    _choose();
  }

  Future<void> _choose() async {
    final client = context.read<AppState>().client;
    final thumb = widget.thumbnail;
    if (thumb != null && await _isPicture(thumb, client)) {
      if (mounted) setState(() => _shown = thumb);
      return;
    }
    final video = widget.video;
    if (video == null) return;
    final local = video.startsWith('/');
    if (!local && client == null) return;
    // Named after the video, without the API key.
    final dir = await ClipPoster.frameDir();
    final name = sha1.convert(utf8.encode(video)).toString();
    final out = '$dir/$name.jpg';
    final ok =
        await File(out).exists() ||
        await (ClipPoster._taking[out] ??= SystemBridge.instance.videoFrame(
          source: local ? video : client!.mediaUrl(video)!,
          headers: local ? const {} : client!.authHeaders,
          out: out,
        ));
    ClipPoster._taking.remove(out);
    if (ok && mounted) setState(() => _shown = out);
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
  Widget build(BuildContext context) {
    final shown = _shown;
    if (shown == null) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    }
    return NetImage(shown, fit: widget.fit, cacheWidth: widget.cacheWidth);
  }
}
