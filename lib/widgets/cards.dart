import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/models.dart';
import '../navigation.dart';
import '../screens/edit/editors.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import 'net_image.dart';

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 2),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed text metrics of the scene and marker cards, so that grids can give
/// them exactly the height their content needs.
class CardText {
  static const _titleSize = 14.0;
  static const _titleHeight = 1.25;
  static const _smallSize = 12.0;
  static const _smallHeight = 1.3;
  static const padding = EdgeInsets.fromLTRB(8, 6, 8, 6);

  // Laid-out text lines are rounded up to whole pixels.
  static double titleLine(BuildContext context) =>
      (MediaQuery.textScalerOf(context).scale(_titleSize) * _titleHeight)
          .ceilToDouble();

  static double smallLine(BuildContext context) =>
      (MediaQuery.textScalerOf(context).scale(_smallSize) * _smallHeight)
          .ceilToDouble();

  static TextStyle title(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyMedium!
      .copyWith(
        fontSize: _titleSize,
        height: _titleHeight,
        fontWeight: FontWeight.w600,
      );

  static TextStyle small(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.bodySmall!
          .copyWith(fontSize: _smallSize, height: _smallHeight, color: color);

  // Forced struts keep every line exactly at the computed height.
  static const titleStrut = StrutStyle(
    fontSize: _titleSize,
    height: _titleHeight,
    forceStrutHeight: true,
  );
  static const smallStrut = StrutStyle(
    fontSize: _smallSize,
    height: _smallHeight,
    forceStrutHeight: true,
  );
}

class SceneCard extends StatefulWidget {
  const SceneCard({super.key, required this.scene});
  final Scene scene;

  /// Height of a card [width] wide: 16:9 thumbnail, two title lines and
  /// three small lines. Space left by a one-line title or a missing studio
  /// is used for extra details rather than left empty.
  static double heightFor(BuildContext context, double width) =>
      width * 9 / 16 +
      CardText.padding.vertical +
      2 * CardText.titleLine(context) +
      3 * CardText.smallLine(context);

  @override
  State<SceneCard> createState() => _SceneCardState();
}

class _SceneCardState extends State<SceneCard> {
  VideoPlayerController? _preview;

  Future<void> _startPreview() async {
    final state = context.read<AppState>();
    final url = state.client?.mediaUrl(widget.scene.preview);
    if (!state.playPreviews || url == null) return;
    final c = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: state.client!.authHeaders,
    );
    setState(() => _preview = c);
    try {
      await c.initialize();
      await c.setVolume(0);
      await c.setLooping(true);
      if (_preview == c) {
        await c.play();
        if (mounted) setState(() {});
      }
    } catch (_) {
      _stopPreview();
    }
  }

  void _stopPreview() {
    final c = _preview;
    if (c == null) return;
    setState(() => _preview = null);
    c.dispose();
  }

  @override
  void dispose() {
    _preview?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final f = s.file;
    final res = f == null ? null : resolutionLabel(f.width, f.height);
    final progress = (s.resumeTime != null && s.duration > 0)
        ? (s.resumeTime! / s.duration).clamp(0.0, 1.0)
        : 0.0;
    final preview = _preview;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => openScene(context, s.id),
        onLongPress: _startPreview,
        onTapCancel: _stopPreview,
        child: Listener(
          onPointerUp: (_) => _stopPreview(),
          onPointerCancel: (_) => _stopPreview(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(s.screenshot, placeholderIcon: Icons.movie),
                    if (s.studio?.hasImage ?? false)
                      StudioWatermark(s.studio!.imagePath!),
                    if (preview != null && preview.value.isInitialized)
                      FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: preview.value.size.width,
                          height: preview.value.size.height,
                          child: VideoPlayer(preview),
                        ),
                      ),
                    Positioned(
                      right: 4,
                      bottom: 6,
                      child: Row(
                        children: [
                          if (res != null) ...[
                            _Badge(res),
                            const SizedBox(width: 4),
                          ],
                          if (s.duration > 0)
                            _Badge(formatDuration(s.duration)),
                        ],
                      ),
                    ),
                    if (progress > 0)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: Colors.black45,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _SceneCardText(scene: s)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneCardText extends StatelessWidget {
  const _SceneCardText({required this.scene});
  final Scene scene;

  /// Details filling the space left by the title and studio lines, most
  /// useful first. The added date and file path always exist, so the area
  /// is never left blank.
  List<TextSpan> _details(BuildContext context) {
    final s = scene;
    final scheme = Theme.of(context).colorScheme;
    final dim = TextStyle(color: scheme.onSurfaceVariant);
    final f = s.file;
    final file = [
      if (f != null && f.size > 0) formatBytes(f.size),
      if (f != null && f.videoCodec.isNotEmpty) f.videoCodec.toUpperCase(),
      if (f != null && f.frameRate > 0) '${f.frameRate.round()} i/s',
    ].join(' • ');
    final added = s.createdAt?.toLocal();
    final parts = [
      if (s.tags.isNotEmpty)
        TextSpan(
          text: s.tags.map((t) => t.name).join(' · '),
          style: TextStyle(color: scheme.primary),
        ),
      if (file.isNotEmpty) TextSpan(text: file, style: dim),
      if (s.details != null && s.details!.trim().isNotEmpty)
        TextSpan(text: s.details!.trim().replaceAll(RegExp(r'\s+'), ' ')),
      if (added != null)
        TextSpan(
          text:
              'Ajoutée le ${added.day.toString().padLeft(2, '0')}/'
              '${added.month.toString().padLeft(2, '0')}/${added.year}',
          style: dim,
        ),
      if (f != null && f.path.isNotEmpty) TextSpan(text: f.path, style: dim),
    ];
    return [
      for (var i = 0; i < parts.length; i++) ...[
        if (i > 0) const TextSpan(text: '\n'),
        parts[i],
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = scene;
    final small = CardText.smallLine(context);
    final dim = Theme.of(context).colorScheme.onSurfaceVariant;
    final meta = [
      if (s.studio != null) s.studio!.name,
      if (s.date != null) s.date!,
    ].join(' • ');

    return Padding(
      padding: CardText.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: CardText.title(context),
            strutStyle: CardText.titleStrut,
          ),
          if (meta.isNotEmpty)
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CardText.small(context),
              strutStyle: CardText.smallStrut,
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final lines = ((box.maxHeight + 0.5) / small).floor();
                if (lines <= 0) return const SizedBox.shrink();
                return Text.rich(
                  TextSpan(children: _details(context)),
                  maxLines: lines,
                  overflow: TextOverflow.ellipsis,
                  style: CardText.small(context),
                  strutStyle: CardText.smallStrut,
                );
              },
            ),
          ),
          SizedBox(
            height: small,
            child: Row(
              children: [
                // Counters shrink on very narrow cards; the stars keep
                // their size on the right.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Stat(Icons.play_arrow, s.playCount, 'lectures', dim),
                        _Stat(Icons.water_drop_outlined, s.oCounter, 'O', dim),
                        _Stat(
                          Icons.person_outline,
                          s.performers.length,
                          'performeurs',
                          dim,
                        ),
                        if (s.organized)
                          Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: dim,
                          ),
                      ],
                    ),
                  ),
                ),
                _Stars(s.rating100, size: small - 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Studio logo in the top-right corner of a scene thumbnail (or of the
/// scene page header). A blurred dark copy behind it keeps light logos
/// readable on light images.
class StudioWatermark extends StatelessWidget {
  const StudioWatermark(this.url, {super.key});
  final String url;

  @override
  Widget build(BuildContext context) {
    Widget logo() => NetImage(
      url,
      fit: BoxFit.contain,
      alignment: Alignment.topRight,
      showPlaceholder: false,
    );
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topRight,
        child: FractionallySizedBox(
          widthFactor: 0.34,
          heightFactor: 0.22,
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 6, right: 6),
            child: Opacity(
              opacity: 0.8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.black54,
                        BlendMode.srcIn,
                      ),
                      child: logo(),
                    ),
                  ),
                  logo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Five small stars filled according to a 1-100 rating (halves included).
class _Stars extends StatelessWidget {
  const _Stars(this.rating100, {required this.size});
  final int? rating100;
  final double size;

  @override
  Widget build(BuildContext context) {
    final stars = starsFromRating(rating100);
    final empty = Theme.of(context).colorScheme.onSurfaceVariant
        .withValues(alpha: 0.45);
    return Tooltip(
      message: rating100 == null ? 'Pas de note' : '$stars / 5',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              stars >= i
                  ? Icons.star
                  : stars >= i - 0.5
                  ? Icons.star_half
                  : Icons.star_border,
              size: size,
              color: stars >= i - 0.5 ? Colors.amber : empty,
            ),
        ],
      ),
    );
  }
}

/// Icon + number in the scene card stats row.
class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label, this.color);
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Zero values are dimmed so non-zero ones stand out.
    final c = value == 0 ? color.withValues(alpha: 0.45) : color;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Tooltip(
        message: '$value $label',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 2),
            Text(
              '$value',
              style: CardText.small(context, color: c),
              strutStyle: CardText.smallStrut,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card with a tall image and a caption, used for performers.
class PerformerCard extends StatelessWidget {
  const PerformerCard({super.key, required this.performer});
  final Performer performer;

  static const aspectRatio = 2 / 3.4;

  static String _subtitle(Performer p, int? age) {
    final parts = [
      if (age != null) '$age ans',
      if (p.disambiguation != null && p.disambiguation!.isNotEmpty)
        p.disambiguation!,
    ];
    if (parts.isNotEmpty) return parts.join(' • ');
    final gender = genderLabel(p.gender);
    return gender.isNotEmpty ? gender : '${p.sceneCount} scènes';
  }

  @override
  Widget build(BuildContext context) {
    final p = performer;
    final theme = Theme.of(context);
    final age = ageFrom(p.birthdate);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => openPerformer(context, p.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(
                    p.imagePath,
                    placeholderIcon: Icons.person,
                    alignment: Alignment.topCenter,
                  ),
                  if (p.favorite)
                    const Positioned(
                      right: 6,
                      top: 6,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Row(
                      children: [
                        if (p.oCounter > 0) ...[
                          _Badge('${p.oCounter}', icon: Icons.water_drop),
                          const SizedBox(width: 4),
                        ],
                        if (p.sceneCount > 0)
                          _Badge('${p.sceneCount}', icon: Icons.movie),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Always one line so every card has the same layout.
                  Text(
                    _subtitle(p, age),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic card for studios, tags and galleries.
class EntityCard extends StatelessWidget {
  const EntityCard({
    super.key,
    required this.title,
    required this.image,
    required this.onTap,
    this.subtitle,
    this.fit = BoxFit.cover,
    this.icon = Icons.image_outlined,
    this.favorite = false,
    this.imagePadding = EdgeInsets.zero,
  });

  final String title;
  final String? image;
  final String? subtitle;
  final VoidCallback onTap;
  final BoxFit fit;
  final IconData icon;
  final bool favorite;
  final EdgeInsets imagePadding;

  static const aspectRatio = 1.05;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: imagePadding,
                    child: NetImage(image, fit: fit, placeholderIcon: icon),
                  ),
                  if (favorite)
                    const Positioned(
                      right: 6,
                      top: 6,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudioCard extends StatelessWidget {
  const StudioCard({super.key, required this.studio});
  final Studio studio;

  @override
  Widget build(BuildContext context) => EntityCard(
    title: studio.name,
    image: studio.imagePath,
    subtitle: '${studio.sceneCount} scènes',
    fit: BoxFit.contain,
    icon: Icons.business,
    favorite: studio.favorite,
    imagePadding: const EdgeInsets.all(12),
    onTap: () => openStudio(context, studio.id),
  );
}

class TagCard extends StatelessWidget {
  const TagCard({super.key, required this.tag});
  final Tag tag;

  @override
  Widget build(BuildContext context) => EntityCard(
    title: tag.name,
    image: tag.imagePath,
    subtitle: '${tag.sceneCount} scènes • ${tag.markerCount} marqueurs',
    icon: Icons.label_outline,
    favorite: tag.favorite,
    onTap: () => openTag(context, tag.id),
  );
}

class GalleryCard extends StatelessWidget {
  const GalleryCard({super.key, required this.gallery});
  final Gallery gallery;

  @override
  Widget build(BuildContext context) => EntityCard(
    title: gallery.displayTitle,
    image: gallery.cover,
    subtitle: [
      '${gallery.imageCount} images',
      if (gallery.date != null) gallery.date!,
    ].join(' • '),
    icon: Icons.photo_library_outlined,
    onTap: () => openGallery(context, gallery.id),
  );
}

class MarkerCard extends StatelessWidget {
  const MarkerCard({super.key, required this.marker});
  final SceneMarker marker;

  Future<void> _actions(BuildContext context) async {
    final m = marker;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.sceneId != null)
              ListTile(
                leading: const Icon(Icons.movie_outlined),
                title: const Text('Ouvrir la scène'),
                onTap: () => Navigator.pop(context, 'scene'),
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifier le marqueur'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'scene':
        openScene(context, m.sceneId!);
      case 'edit':
        await editMarker(context, m);
    }
  }

  /// Height of a card [width] wide: thumbnail, title and one small line.
  static double heightFor(BuildContext context, double width) =>
      width * 9 / 16 +
      CardText.padding.vertical +
      CardText.titleLine(context) +
      CardText.smallLine(context);

  @override
  Widget build(BuildContext context) {
    final m = marker;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: m.sceneId == null
            ? null
            : () => playScene(context, m.sceneId!, start: m.seconds),
        onLongPress: () => _actions(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(m.screenshot, placeholderIcon: Icons.bookmark),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: _Badge(
                      formatDuration(m.seconds),
                      icon: Icons.play_arrow,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: CardText.padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CardText.title(context),
                    strutStyle: CardText.titleStrut,
                  ),
                  Text(
                    m.sceneTitle ?? m.primaryTag.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CardText.small(context),
                    strutStyle: CardText.smallStrut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Group (DVD-style) card with the front cover.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group});
  final Group group;

  static const aspectRatio = 2 / 3.4;

  @override
  Widget build(BuildContext context) {
    final g = group;
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => openGroup(context, g.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(g.frontImage, placeholderIcon: Icons.video_library),
                  if (g.sceneCount > 0)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: _Badge('${g.sceneCount}', icon: Icons.movie),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    [
                      if (g.studio != null) g.studio!.name,
                      if (g.date != null) g.date!,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
