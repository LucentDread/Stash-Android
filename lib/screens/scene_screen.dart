import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import '../navigation.dart';
import '../services/app_state.dart';
import '../services/downloads.dart';
import '../services/system_bridge.dart';
import '../utils/format.dart';
import '../widgets/async_view.dart';
import '../widgets/cards.dart';
import '../widgets/data_refresh.dart';
import '../widgets/detail_widgets.dart';
import '../widgets/download_button.dart';
import '../widgets/insets.dart';
import '../widgets/net_image.dart';
import '../widgets/tv_focus.dart';
import 'edit/editors.dart';

class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key, required this.sceneId});
  final String sceneId;

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> with DataRefresh {
  late final _repo = context.read<AppState>().repo!;
  Scene? _scene;
  Object? _error;
  int? _oCounter;
  int? _rating;

  /// How far the title under the image has slid under the app bar, from 0
  /// (fully visible) to 1 (hidden): it fades out there while the app bar's
  /// copy fades in at the same pace.
  final _titleShift = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleShift.dispose();
    super.dispose();
  }

  /// Updates [_titleShift] from the scroll position: the page title sits
  /// right under the image ([expanded] tall) and the page padding.
  bool _onScroll(ScrollNotification n, double expanded, double titleHeight) {
    if (n.depth != 0) return false;
    final barBottom = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final titleTop = expanded + 16 - n.metrics.pixels;
    _titleShift.value = ((barBottom - titleTop) / titleHeight).clamp(0.0, 1.0);
    return false;
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final s = await _repo.findScene(widget.sceneId);
      if (!mounted) return;
      setState(() {
        _scene = s;
        _oCounter = s.oCounter;
        _rating = s.rating100;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _play({double? start}) async {
    await playScene(context, widget.sceneId, start: start);
    // Refresh resume position and play count.
    if (mounted) _load();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    watchServerData(_load);
    final s = _scene;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _error != null
            ? ErrorView(error: _error!, onRetry: _load)
            : const Center(child: CircularProgressIndicator()),
      );
    }
    return SystemBridge.instance.isTv ? _tvPage(s) : _phonePage(s);
  }

  /// Phone and tablet: the picture on top (tap to play) under a
  /// collapsing app bar with the download and edit buttons.
  Widget _phonePage(Scene s) {
    final theme = Theme.of(context);
    final expanded = MediaQuery.sizeOf(context).width * 9 / 16;
    // The fade spans the title's first line.
    final titleStyle = theme.textTheme.titleLarge;
    final titleHeight =
        MediaQuery.textScalerOf(context).scale(titleStyle?.fontSize ?? 22) *
        (titleStyle?.height ?? 1.2);
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) => _onScroll(n, expanded, titleHeight),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: ValueListenableBuilder(
                valueListenable: _titleShift,
                builder: (_, shift, child) =>
                    Opacity(opacity: shift, child: child),
                child: Text(s.displayTitle, overflow: TextOverflow.ellipsis),
              ),
              actions: _pageActions(s),
              expandedHeight: expanded,
              flexibleSpace: FlexibleSpaceBar(
                background: GestureDetector(
                  onTap: () => _play(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetImage(s.screenshot, placeholderIcon: Icons.movie),
                      if (s.studio?.hasImage ?? false)
                        // Under the app bar buttons, as on the scene cards.
                        Padding(
                          padding: EdgeInsets.only(
                            top:
                                MediaQuery.paddingOf(context).top +
                                kToolbarHeight,
                          ),
                          child: StudioWatermark(s.studio!.imagePath!),
                        ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black54, Colors.transparent],
                            stops: [0, 0.4],
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 72,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: withNavBar(context, const EdgeInsets.all(16)),
              sliver: SliverList.list(
                children: [
                  ValueListenableBuilder(
                    valueListenable: _titleShift,
                    builder: (_, shift, child) =>
                        Opacity(opacity: 1 - shift, child: child),
                    child: Text(
                      s.displayTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ..._summary(s),
                  const SizedBox(height: 12),
                  _playRow(s),
                  const SizedBox(height: 8),
                  _ratingRow(s),
                  ..._sections(s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TV, like the TV apps of media servers: the picture in the background
  /// of the top right, fading into the page; the title, details and
  /// buttons over it on the left (Play has the focus); the rest below.
  /// No app bar: the remote's Back leaves the page.
  Widget _tvPage(Scene s) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final background = theme.colorScheme.surface;
    const side = 48.0;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SizedBox(
            height: size.height * 0.62,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  width: size.width * 0.62,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetImage(s.screenshot, placeholderIcon: Icons.movie),
                      if (s.studio?.hasImage ?? false)
                        StudioWatermark(s.studio!.imagePath!),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              background,
                              background.withValues(alpha: 0),
                            ],
                            stops: const [0, 0.5],
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              background,
                              background.withValues(alpha: 0),
                            ],
                            stops: const [0, 0.4],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: side,
                  bottom: 16,
                  width: size.width * 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.displayTitle,
                        style: theme.textTheme.headlineMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ..._summary(s),
                      const SizedBox(height: 12),
                      _ratingRow(s),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ..._playButtons(s, autofocus: true),
                          ..._pageActions(s),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: side),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _sections(s),
            ),
          ),
        ],
      ),
    );
  }

  /// Download and edit.
  List<Widget> _pageActions(Scene s) => [
    DownloadButton(kind: OfflineKind.scene, id: s.id, sizeHint: s.file?.size),
    EditButton(onEdit: () => editScene(context, s), onSaved: _load),
  ];

  /// Date, duration, resolution, plays; the studio.
  List<Widget> _summary(Scene s) {
    final theme = Theme.of(context);
    final f = s.file;
    return [
      Wrap(
        spacing: 12,
        children: [
          if (s.date != null) Text(s.date!),
          if (s.duration > 0) Text(formatDuration(s.duration)),
          if (f != null && resolutionLabel(f.width, f.height) != null)
            Text(resolutionLabel(f.width, f.height)!),
          if (s.playCount > 0) Text(tr.countPlays(s.playCount)),
        ],
      ),
      if (s.studio != null) ...[
        const SizedBox(height: 4),
        InkWell(
          onTap: () => openStudio(context, s.studio!.id),
          child: Text(
            s.studio!.name,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    ];
  }

  /// Play (or resume), from the start, forget the resume position.
  List<Widget> _playButtons(Scene s, {bool autofocus = false}) {
    final resume = s.resumeTime ?? 0;
    final canResume = resume > 5 && resume < s.duration - 5;
    return [
      FilledButton.icon(
        autofocus: autofocus,
        onPressed: () => _play(start: canResume ? null : 0),
        icon: const Icon(Icons.play_arrow),
        label: Text(canResume ? tr.resumeAt(formatDuration(resume)) : tr.play),
      ),
      if (canResume)
        OutlinedButton(
          onPressed: () => _play(start: 0),
          child: Text(tr.fromStart),
        ),
      if (resume > 0)
        IconButton(
          tooltip: tr.forgetResumePosition,
          icon: const Icon(Icons.history_toggle_off),
          onPressed: () => _run(() async {
            final messenger = ScaffoldMessenger.of(context);
            await _repo.resetResume(s.id);
            await _load();
            messenger.showSnackBar(
              SnackBar(content: Text(tr.resumePositionCleared)),
            );
          }),
        ),
    ];
  }

  /// The play buttons on a phone: Play stretches.
  Widget _playRow(Scene s) {
    final buttons = _playButtons(s);
    return Row(
      children: [
        Expanded(child: buttons.first),
        for (final b in buttons.skip(1)) ...[const SizedBox(width: 8), b],
      ],
    );
  }

  /// Rating stars and O counter.
  Widget _ratingRow(Scene s) => Row(
    mainAxisSize: SystemBridge.instance.isTv
        ? MainAxisSize.min
        : MainAxisSize.max,
    children: [
      StarRating(
        rating100: _rating,
        onChanged: (r) => _run(() async {
          final old = _rating;
          setState(() => _rating = r);
          try {
            await _repo.rateScene(s.id, r);
          } catch (_) {
            if (mounted) setState(() => _rating = old);
            rethrow;
          }
        }),
      ),
      if (SystemBridge.instance.isTv)
        const SizedBox(width: 24)
      else
        const Spacer(),
      TextButton.icon(
        onPressed: () => _run(() async {
          final c = await _repo.addO(s.id);
          if (mounted) setState(() => _oCounter = c);
        }),
        // Long press undoes the last increment.
        onLongPress: (_oCounter ?? 0) == 0
            ? null
            : () => _run(() async {
                final c = await _repo.removeO(s.id);
                if (mounted) setState(() => _oCounter = c);
              }),
        icon: const Icon(Icons.water_drop_outlined),
        label: Text('${_oCounter ?? 0}'),
      ),
    ],
  );

  /// Performers, markers, description, tags, groups, galleries, file
  /// information, links.
  List<Widget> _sections(Scene s) {
    final theme = Theme.of(context);
    final f = s.file;
    return [
      if (s.performers.isNotEmpty)
        Section(
          title: tr.performers,
          child: RefChips(
            refs: s.performers,
            icon: Icons.person,
            onTap: (r) => openPerformer(context, r.id),
          ),
        ),
      if (s.markers.isNotEmpty)
        Section(
          title: tr.markers,
          child: SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: s.markers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final m = s.markers[i];
                return SizedBox(
                  width: 160,
                  child: FocusFrame(
                    radius: 8,
                    child: InkWell(
                      onTap: () => _play(start: m.seconds),
                      onLongPress: () async {
                        if (await editMarker(context, m)) _load();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: NetImage(
                                m.screenshot,
                                placeholderIcon: Icons.bookmark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatDuration(m.seconds)} • ${m.displayTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      if (s.details != null && s.details!.isNotEmpty)
        Section(title: tr.description, child: SelectableText(s.details!)),
      if (s.tags.isNotEmpty)
        Section(
          title: tr.tags,
          child: RefChips(refs: s.tags, onTap: (r) => openTag(context, r.id)),
        ),
      if (s.groups.isNotEmpty)
        Section(
          title: tr.groups,
          child: RefChips(
            refs: s.groups,
            icon: Icons.video_library_outlined,
            onTap: (r) => openGroup(context, r.id),
          ),
        ),
      if (s.galleries.isNotEmpty)
        Section(
          title: tr.galleries,
          child: RefChips(
            refs: s.galleries,
            icon: Icons.photo_library_outlined,
            onTap: (r) => openGallery(context, r.id),
          ),
        ),
      Section(
        title: tr.information,
        child: InfoTable([
          (tr.code, s.code),
          (tr.director, s.director),
          if (f != null) ...[
            (tr.file, f.path),
            (tr.fileSize, formatBytes(f.size)),
            (tr.dimensions, '${f.width} × ${f.height}'),
            (tr.format, f.format),
            (tr.video, f.videoCodec),
            (tr.audio, f.audioCodec),
            (tr.framesPerSecondLabel, f.frameRate.toStringAsFixed(2)),
            (
              tr.bitRate,
              tr.megabitsPerSecond((f.bitRate / 1000000).toStringAsFixed(2)),
            ),
          ],
          (tr.sortLastPlayed, s.lastPlayedAt?.split('T').first),
        ]),
      ),
      if (s.urls.isNotEmpty) Section(title: tr.links, child: UrlList(s.urls)),
    ];
  }
}
