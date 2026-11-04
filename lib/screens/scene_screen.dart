import 'dart:ui';

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

  /// Scroll of the wide page (parallax, back to the top).
  final _wideScroll = ScrollController();

  /// The wide page's title (in its header), and whether it has scrolled
  /// under the top bar: the bar then shows it.
  final _wideTitle = GlobalKey();
  final _wideTitleGone = ValueNotifier<bool>(false);

  void _checkWideTitle() {
    final box = _wideTitle.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !mounted) return;
    final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    _wideTitleGone.value =
        bottom < MediaQuery.paddingOf(context).top + _barHeight;
  }

  /// Height of the wide page's title bar, under the status bar.
  static const _barHeight = 56.0;

  @override
  void initState() {
    super.initState();
    // After the frame's layout, where the title has moved.
    _wideScroll.addListener(
      () => WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkWideTitle(),
      ),
    );
    _load();
  }

  @override
  void dispose() {
    _titleShift.dispose();
    _wideScroll.dispose();
    _wideTitleGone.dispose();
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
    return _wideLayout ? _widePage(s) : _phonePage(s);
  }

  /// TVs, and tablets in landscape: room for the picture beside the
  /// title and buttons.
  bool get _wideLayout {
    if (SystemBridge.instance.isTv) return true;
    final size = MediaQuery.sizeOf(context);
    return size.width >= 840 && size.width > size.height;
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

  /// TV and landscape tablet, like the TV apps of media servers: the
  /// picture in the background of the top right, fading into the page;
  /// the title, details and buttons over it on the left; the rest below.
  /// Scrolling down, the picture slides slower than the page and blurs
  /// (parallax), and a bar with the title stays at the top. No app bar:
  /// on a TV the remote's Back leaves the page (and Play has the focus);
  /// on a touch screen, a back button sits in the corner (and in the
  /// title bar) and a tap on the picture plays.
  Widget _widePage(Scene s) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final background = theme.colorScheme.surface;
    final tv = SystemBridge.instance.isTv;
    const side = 48.0;
    final heroHeight = size.height * 0.62;

    // Slides at half the scroll speed and blurs, up to a point.
    final picture = AnimatedBuilder(
      animation: _wideScroll,
      builder: (context, child) {
        final offset = _wideScroll.hasClients
            ? _wideScroll.offset.clamp(0.0, heroHeight)
            : 0.0;
        final sigma = (offset / heroHeight * 16).clamp(0.0, 12.0);
        return Transform.translate(
          offset: Offset(0, offset * 0.5),
          child: sigma < 0.5
              ? child
              : ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: sigma,
                    sigmaY: sigma,
                    // Its edges keep their color instead of darkening.
                    tileMode: TileMode.clamp,
                  ),
                  child: child,
                ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetImage(s.screenshot, placeholderIcon: Icons.movie),
          if (s.studio?.hasImage ?? false)
            StudioWatermark(s.studio!.imagePath!),
        ],
      ),
    );
    final fades = [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // A solid band at the edge: under the stretch of an overscroll
            // or a fractional position, the picture's last pixels would
            // otherwise show as a line.
            colors: [background, background, background.withValues(alpha: 0)],
            stops: const [0, 0.03, 0.5],
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [background, background, background.withValues(alpha: 0)],
            stops: const [0, 0.04, 0.4],
          ),
        ),
      ),
    ];
    final pictureArea = ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Stops short of the area's left and bottom edges, inside the
          // fades' solid bands: on an edge that falls between two pixels
          // (or stretched by an overscroll), the picture would show
          // through as a thin line.
          Positioned(
            left: 8,
            top: 0,
            right: 0,
            bottom: 8,
            child: ClipRect(child: picture),
          ),
          ...fades,
          if (!tv)
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 72,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );

    final hero = SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: size.width * 0.62,
            child: tv
                ? pictureArea
                : GestureDetector(onTap: () => _play(), child: pictureArea),
          ),
          if (!tv) Positioned(top: top + 8, left: 8, child: const BackButton()),
          Positioned(
            left: side,
            bottom: 16,
            width: size.width * 0.5,
            // Back to the top of the page whenever these buttons get the
            // focus again: they sit low in the header, so revealing just
            // them would leave the picture cut.
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onFocusChange: (focused) {
                if (focused && _wideScroll.hasClients) {
                  _wideScroll.animateTo(
                    0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.displayTitle,
                    key: _wideTitle,
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
                      ..._playButtons(s, autofocus: tv),
                      ..._pageActions(s),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Up/Down go row by row (see TvTraversalPolicy).
          FocusTraversalGroup(
            policy: TvTraversalPolicy(rowsFirst: true),
            child: CustomScrollView(
              controller: _wideScroll,
              slivers: [
                SliverToBoxAdapter(child: hero),
                // The title bar's room once stuck to the top: pinned, so
                // that the page keeps what gets the focus out from under
                // the bar.
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _BarRoom(top + _barHeight),
                ),
                SliverPadding(
                  padding: withNavBar(
                    context,
                    const EdgeInsets.fromLTRB(side, 0, side, 32),
                  ),
                  sliver: SliverList.list(children: _sections(s)),
                ),
              ],
            ),
          ),
          // Shows as soon as the header's title has scrolled under it.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder(
              valueListenable: _wideTitleGone,
              builder: (_, gone, _) => _TitleBar(
                visible: gone,
                title: s.displayTitle,
                height: top + _barHeight,
                topPadding: top,
                back: !tv,
                color: background,
                side: tv ? side : 8,
              ),
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
    mainAxisSize: _wideLayout ? MainAxisSize.min : MainAxisSize.max,
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
      if (_wideLayout) const SizedBox(width: 24) else const Spacer(),
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
        Section(title: tr.description, child: DetailText(s.details!)),
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

/// Room for the wide scene page's title bar, pinned to the top once
/// scrolled there; the bar itself lies over the page.
class _BarRoom extends SliverPersistentHeaderDelegate {
  _BarRoom(this.height);
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(height: height);

  @override
  bool shouldRebuild(_BarRoom old) => height != old.height;
}

/// The wide scene page's title bar, over the page's color, with a back
/// button on touch screens: [visible] once the header's title has
/// scrolled away.
class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.visible,
    required this.title,
    required this.height,
    required this.topPadding,
    required this.back,
    required this.color,
    required this.side,
  });

  final bool visible;
  final String title;
  final double height;
  final double topPadding;
  final bool back;
  final Color color;
  final double side;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      // Not reachable while invisible.
      child: ExcludeFocus(
        excluding: !visible,
        child: IgnorePointer(
          ignoring: !visible,
          child: Material(
            color: color,
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding,
                left: side,
                right: side,
              ),
              child: Row(
                children: [
                  if (back) const BackButton(),
                  if (back) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
