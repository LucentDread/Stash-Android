import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../api/stash_repository.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import 'app_state.dart';

enum OfflineKind { scene, group, gallery, image }

enum FileState { queued, running, paused, done, failed }

/// One file of an offline item, stored under the offline root.
class OfflineFile {
  OfflineFile({
    required this.taskId,
    required this.url,
    required this.path,
    this.video = false,
  });

  final String taskId;
  final String url;

  /// Path relative to the offline root.
  final String path;

  /// Video files get a system notification and drive the item's progress.
  final bool video;

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'url': url,
    'path': path,
    'video': video,
  };

  factory OfflineFile.fromJson(Map<String, dynamic> j) => OfflineFile(
    taskId: j['taskId'] as String,
    url: j['url'] as String,
    path: j['path'] as String,
    video: j['video'] as bool? ?? false,
  );
}

/// A scene, group or gallery available offline: its Stash data (as
/// returned by the API) and its local files.
class OfflineEntry {
  OfflineEntry({
    required this.kind,
    required this.id,
    required this.title,
    required this.data,
    required this.files,
    required this.added,
    this.cover,
    this.sceneIds = const [],
    this.bytes,
  });

  final OfflineKind kind;
  final String id;
  final String title;
  final Map<String, dynamic> data;
  final List<OfflineFile> files;
  final DateTime added;

  /// Cover image path, relative to the offline root.
  final String? cover;

  /// Scenes of a group (each one is its own scene entry).
  final List<String> sceneIds;

  /// Expected size of the video, when known.
  final int? bytes;

  String get key => keyOf(kind, id);
  static String keyOf(OfflineKind kind, String id) => '${kind.name}_$id';

  OfflineFile? get video => files.where((f) => f.video).firstOrNull;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'id': id,
    'title': title,
    'data': data,
    'files': [for (final f in files) f.toJson()],
    'added': added.toIso8601String(),
    'cover': cover,
    'sceneIds': sceneIds,
    'bytes': bytes,
  };

  factory OfflineEntry.fromJson(Map<String, dynamic> j) => OfflineEntry(
    kind: OfflineKind.values.byName(j['kind'] as String),
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    data: (j['data'] as Map).cast<String, dynamic>(),
    files: [
      for (final f in j['files'] as List)
        OfflineFile.fromJson((f as Map).cast<String, dynamic>()),
    ],
    added: DateTime.tryParse(j['added'] as String? ?? '') ?? DateTime(2000),
    cover: j['cover'] as String?,
    sceneIds: (j['sceneIds'] as List?)?.cast<String>() ?? const [],
    bytes: j['bytes'] as int?,
  );
}

/// Progress update of one file transfer.
typedef FileUpdate = ({String taskId, FileState state, double? progress});

/// Transfers files in the background. Abstracted so tests can fake it.
abstract class FileFetcher {
  /// Absolute directory holding the offline files.
  Future<String> rootPath();

  /// Starts the fetcher; returns the last known state of tracked files.
  Future<Map<String, FileState>> start();

  Stream<FileUpdate> get updates;

  Future<void> enqueue({
    required String taskId,
    required String url,
    required Map<String, String> headers,
    required String path,
    required String displayName,
    required bool notify,
  });

  Future<void> cancel(Iterable<String> taskIds);
}

/// Offline copies of scenes, groups, galleries and single images.
class DownloadManager extends ChangeNotifier {
  DownloadManager(this._app, this._fetcher);

  final AppState _app;
  final FileFetcher _fetcher;

  final Map<String, OfflineEntry> _entries = {};
  final Map<String, FileState> _states = {};
  final Map<String, double> _progress = {};
  String? _root;
  Future<void>? _ready;
  StreamSubscription<FileUpdate>? _sub;

  /// Loads the index and starts listening to transfers. Safe to call often.
  Future<void> init() => _ready ??= _init();

  Future<void> _init() async {
    _root = await _fetcher.rootPath();
    final index = File('$_root/index.json');
    if (await index.exists()) {
      try {
        final list = jsonDecode(await index.readAsString()) as List;
        for (final e in list) {
          final entry = OfflineEntry.fromJson(
            (e as Map).cast<String, dynamic>(),
          );
          _entries[entry.key] = entry;
        }
      } catch (_) {
        // Unreadable index: start over, files stay on disk.
      }
    }
    _sub = _fetcher.updates.listen(_onUpdate);
    final known = await _fetcher.start();
    for (final entry in _entries.values) {
      for (final f in entry.files) {
        if (await File(absolute(f.path)).exists() &&
            known[f.taskId] != FileState.running &&
            known[f.taskId] != FileState.queued) {
          _states[f.taskId] = FileState.done;
        } else {
          _states[f.taskId] = known[f.taskId] ?? FileState.failed;
        }
      }
    }
    notifyListeners();
  }

  void _onUpdate(FileUpdate u) {
    _states[u.taskId] = u.state;
    if (u.progress != null && u.progress! >= 0) {
      _progress[u.taskId] = u.progress!;
    }
    notifyListeners();
  }

  String absolute(String relative) => '$_root/$relative';

  List<OfflineEntry> entries(OfflineKind kind) =>
      _entries.values.where((e) => e.kind == kind).toList()
        ..sort((a, b) => b.added.compareTo(a.added));

  OfflineEntry? entry(OfflineKind kind, String id) =>
      _entries[OfflineEntry.keyOf(kind, id)];

  bool get isEmpty => _entries.isEmpty;

  /// Overall state of an entry and its progress (0-1, null if unknown).
  (FileState, double?) status(OfflineEntry e) {
    final files = e.kind == OfflineKind.group
        ? [
            for (final id in e.sceneIds)
              ...?_entries[OfflineEntry.keyOf(OfflineKind.scene, id)]?.files,
            ...e.files,
          ]
        : e.files;
    if (files.isEmpty) return (FileState.done, 1);
    final states = [
      for (final f in files) _states[f.taskId] ?? FileState.queued,
    ];
    if (states.every((s) => s == FileState.done)) return (FileState.done, 1);
    if (states.any((s) => s == FileState.failed)) {
      return (FileState.failed, null);
    }

    // Videos dominate the transfer time, so they drive the progress.
    final tracked = files.where((f) => f.video).toList();
    final measured = tracked.isEmpty ? files : tracked;
    var sum = 0.0;
    for (final f in measured) {
      sum += _states[f.taskId] == FileState.done
          ? 1
          : (_progress[f.taskId] ?? 0);
    }
    final state = states.any((s) => s == FileState.running)
        ? FileState.running
        : states.any((s) => s == FileState.paused)
        ? FileState.paused
        : FileState.queued;
    return (state, sum / measured.length);
  }

  bool isDone(OfflineEntry e) => status(e).$1 == FileState.done;

  /// Local path of a downloaded scene's video.
  String? videoPath(OfflineEntry e) {
    final v = e.video;
    return v == null ? null : absolute(v.path);
  }

  String? coverPath(OfflineEntry e) =>
      e.cover == null ? null : absolute(e.cover!);

  StashRepository get _repo {
    final repo = _app.repo;
    if (repo == null) throw StateError(tr.noServerConfigured);
    return repo;
  }

  Map<String, String> get _headers => _app.client?.authHeaders ?? const {};

  String _url(String? url) {
    final u = _app.client?.mediaUrl(url);
    if (u == null) throw StateError(tr.fileUnavailable);
    return u;
  }

  Future<void> _fetch(OfflineFile f, String displayName) {
    _states[f.taskId] = FileState.queued;
    return _fetcher.enqueue(
      taskId: f.taskId,
      url: f.url,
      headers: _headers,
      path: f.path,
      displayName: displayName,
      notify: f.video,
    );
  }

  Future<void> _add(OfflineEntry e, String displayName) async {
    _entries[e.key] = e;
    await _save();
    for (final f in e.files) {
      await _fetch(f, displayName);
    }
    notifyListeners();
  }

  static String _ext(String path, String fallback) {
    final name = path.split(RegExp(r'[\\/]')).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 && dot < name.length - 1
        ? name.substring(dot + 1).toLowerCase()
        : fallback;
  }

  /// Downloads a scene's original file, cover and data.
  Future<void> downloadScene(String id) async {
    await init();
    if (entry(OfflineKind.scene, id) != null) return;
    final data = await _repo.sceneJson(id);
    final scene = Scene.fromJson(data);
    final dir = 'scene_$id';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await _add(
      OfflineEntry(
        kind: OfflineKind.scene,
        id: id,
        title: scene.displayTitle,
        data: data,
        added: DateTime.now(),
        bytes: scene.file?.size,
        cover: scene.screenshot == null ? null : '$dir/cover.jpg',
        files: [
          OfflineFile(
            taskId: 'scene-$id-video-$stamp',
            url: _url(scene.stream),
            path: '$dir/video.${_ext(scene.file?.path ?? '', 'mp4')}',
            video: true,
          ),
          if (scene.screenshot != null)
            OfflineFile(
              taskId: 'scene-$id-cover-$stamp',
              url: _url(scene.screenshot),
              path: '$dir/cover.jpg',
            ),
        ],
      ),
      scene.displayTitle,
    );
  }

  /// Downloads every scene of a group (in group order) and its covers.
  Future<int> downloadGroup(String id) async {
    await init();
    final data = await _repo.groupJson(id);
    final group = Group.fromJson(data);
    final sceneIds = <String>[];
    for (var page = 1; ; page++) {
      final r = await _repo.findScenes(
        ListQuery(
          page: page,
          perPage: 100,
          sort: 'group_scene_number',
          descending: false,
        ),
        entity: EntityFilter.group(id),
      );
      sceneIds.addAll(r.items.map((s) => s.id));
      if (sceneIds.length >= r.count || r.items.isEmpty) break;
    }
    final dir = 'group_$id';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await _add(
      OfflineEntry(
        kind: OfflineKind.group,
        id: id,
        title: group.name,
        data: data,
        added: DateTime.now(),
        sceneIds: sceneIds,
        cover: group.frontImage == null ? null : '$dir/front.jpg',
        files: [
          if (group.frontImage != null)
            OfflineFile(
              taskId: 'group-$id-front-$stamp',
              url: _url(group.frontImage),
              path: '$dir/front.jpg',
            ),
        ],
      ),
      group.name,
    );
    for (final sceneId in sceneIds) {
      await downloadScene(sceneId);
    }
    return sceneIds.length;
  }

  /// Downloads every image of a gallery.
  Future<int> downloadGallery(String id) async {
    await init();
    if (entry(OfflineKind.gallery, id) != null) return 0;
    final data = await _repo.galleryJson(id);
    final gallery = Gallery.fromJson(data);
    final images = <StashImage>[];
    for (var page = 1; ; page++) {
      final r = await _repo.findImages(
        ListQuery(page: page, perPage: 100, sort: 'path', descending: false),
        entity: EntityFilter.gallery(id),
      );
      images.addAll(r.items);
      if (images.length >= r.count || r.items.isEmpty) break;
    }
    final dir = 'gallery_$id';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await _add(
      OfflineEntry(
        kind: OfflineKind.gallery,
        id: id,
        title: gallery.displayTitle,
        data: data,
        added: DateTime.now(),
        cover: images.firstOrNull?.thumbnail == null ? null : '$dir/$_thumb',
        files: [
          if (images.firstOrNull?.thumbnail case final thumb?)
            OfflineFile(
              taskId: 'gallery-$id-cover-$stamp',
              url: _url(thumb),
              path: '$dir/$_thumb',
            ),
          for (var i = 0; i < images.length; i++)
            if (images[i].image != null)
              OfflineFile(
                taskId: 'gallery-$id-$i-$stamp',
                url: _url(images[i].image),
                path: '$dir/${_imageName(i, images[i])}',
              ),
        ],
      ),
      gallery.displayTitle,
    );
    return images.length;
  }

  /// Downloads one image (from the Images list, a view or a gallery).
  Future<void> downloadImage(String id) async {
    await init();
    if (entry(OfflineKind.image, id) != null) return;
    final image = await _repo.findImage(id);
    final title = (image.title?.isNotEmpty ?? false)
        ? image.title!
        : tr.imageNumber(id);
    final path = image.isClip
        ? 'image_$id/image${StashImage.clipExtension}'
        : 'image_$id/image.img';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await _add(
      OfflineEntry(
        kind: OfflineKind.image,
        id: id,
        title: title,
        data: {'id': id, 'title': image.title},
        added: DateTime.now(),
        cover: image.thumbnail == null ? null : 'image_$id/$_thumb',
        files: [
          if (image.image != null)
            OfflineFile(
              taskId: 'image-$id-$stamp',
              url: _url(image.image),
              path: path,
            ),
          if (image.thumbnail != null)
            OfflineFile(
              taskId: 'image-$id-thumb-$stamp',
              url: _url(image.thumbnail),
              path: 'image_$id/$_thumb',
            ),
        ],
      ),
      title,
    );
  }

  /// Small preview of an image (or of a gallery's first one), as Stash
  /// makes it: clips have one too.
  static const _thumb = 'thumb.jpg';

  /// File name of a gallery's [i]th image; clips are named so the viewer
  /// plays them.
  static String _imageName(int i, StashImage image) =>
      '${(i + 1).toString().padLeft(5, '0')}'
      '${image.isClip ? StashImage.clipExtension : '.img'}';

  /// Local image paths of a downloaded gallery (or single image), in
  /// order.
  List<String> galleryImages(OfflineEntry e) => [
    for (final f in e.files)
      if (_states[f.taskId] == FileState.done &&
          (f.path.endsWith('.img') ||
              f.path.endsWith(StashImage.clipExtension)))
        absolute(f.path),
  ];

  /// Number of images (and clips) of a downloaded gallery.
  int galleryImageCount(OfflineEntry e) => e.files
      .where(
        (f) =>
            f.path.endsWith('.img') ||
            f.path.endsWith(StashImage.clipExtension),
      )
      .length;

  /// Restarts the files that failed.
  Future<void> retry(OfflineEntry e) async {
    final files = e.kind == OfflineKind.group
        ? [
            for (final id in e.sceneIds)
              ...?_entries[OfflineEntry.keyOf(OfflineKind.scene, id)]?.files,
            ...e.files,
          ]
        : e.files;
    for (final f in files) {
      if (_states[f.taskId] != FileState.done) await _fetch(f, e.title);
    }
    notifyListeners();
  }

  /// Removes an entry and its files. A group also removes its scenes.
  Future<void> delete(OfflineEntry e) async {
    final victims = [
      e,
      if (e.kind == OfflineKind.group)
        for (final id in e.sceneIds)
          ?_entries[OfflineEntry.keyOf(OfflineKind.scene, id)],
    ];
    for (final v in victims) {
      await _fetcher.cancel(v.files.map((f) => f.taskId));
      _entries.remove(v.key);
      for (final f in v.files) {
        _states.remove(f.taskId);
        _progress.remove(f.taskId);
      }
      final dir = Directory(absolute('${v.kind.name}_${v.id}'));
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final file = File('$_root/index.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode([for (final e in _entries.values) e.toJson()]),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
