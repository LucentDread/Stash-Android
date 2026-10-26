import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/api/stash_client.dart';
import 'package:stash_android/api/stash_repository.dart';
import 'package:stash_android/main.dart';
import 'package:stash_android/models/models.dart';
import 'package:stash_android/screens/downloads_screen.dart';
import 'package:stash_android/screens/image_viewer_screen.dart';
import 'package:stash_android/services/app_state.dart';
import 'package:stash_android/services/downloads.dart';
import 'package:stash_android/widgets/net_image.dart';
import 'package:stash_android/widgets/view_list.dart';
import 'package:video_player/video_player.dart';
import 'package:stash_android/screens/browse_screens.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Records transfers; tests push their progress through [emit].
/// Player that opens any clip at once: 12 s long, at 3 s.
class _FakePlayer extends VideoPlayerPlatform {
  final playing = <int, bool>{};
  final seeks = <Duration>[];
  var _next = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => _next++;

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 12),
      size: const Size(640, 360),
    ),
  );

  @override
  Future<void> play(int playerId) async => playing[playerId] = true;

  @override
  Future<void> pause(int playerId) async => playing[playerId] = false;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async =>
      seeks.add(position);

  @override
  Future<Duration> getPosition(int playerId) async =>
      const Duration(seconds: 3);

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> setAllowBackgroundPlayback(bool allow) async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}

class FakeFetcher implements FileFetcher {
  FakeFetcher(this.root);
  final String root;
  final enqueued = <String, ({String url, String path, bool notify})>{};
  final canceled = <String>[];
  final _updates = StreamController<FileUpdate>.broadcast();
  Map<String, FileState> known = {};

  void emit(String taskId, FileState state, [double? progress]) {
    if (state == FileState.done) {
      final f = File('$root/${enqueued[taskId]!.path}')
        ..createSync(recursive: true);
      f.writeAsStringSync('data');
    }
    _updates.add((taskId: taskId, state: state, progress: progress));
  }

  @override
  Future<String> rootPath() async => root;
  @override
  Future<Map<String, FileState>> start() async => known;
  @override
  Stream<FileUpdate> get updates => _updates.stream;
  @override
  Future<void> enqueue({
    required String taskId,
    required String url,
    required Map<String, String> headers,
    required String path,
    required String displayName,
    required bool notify,
  }) async => enqueued[taskId] = (url: url, path: path, notify: notify);
  @override
  Future<void> cancel(Iterable<String> taskIds) async =>
      canceled.addAll(taskIds);
}

Map<String, dynamic> _scene(String id) => {
  'id': id,
  'title': 'Scène $id',
  'files': [
    {'path': '/data/scene$id.mkv', 'size': 1000, 'duration': 60},
  ],
  'paths': {
    'screenshot': 'http://stash.test/scene/$id/screenshot',
    'stream': 'http://stash.test/scene/$id/stream',
  },
};

/// Fake server for scenes 1-2, group 5 (both scenes) and gallery 8.
http.Client _server() => MockClient((req) async {
  final body = jsonDecode(req.body) as Map<String, dynamic>;
  final q = body['query'] as String;
  final v = body['variables'] as Map<String, dynamic>? ?? const {};
  Object data;
  if (q.contains('findScene(')) {
    data = {'findScene': _scene(v['id'] as String)};
  } else if (q.contains('findScenes')) {
    data = {
      'findScenes': {
        'count': 2,
        'scenes': [_scene('1'), _scene('2')],
      },
    };
  } else if (q.contains('findGroup(')) {
    data = {
      'findGroup': {
        'id': '5',
        'name': 'Saga',
        'front_image_path': 'http://stash.test/group/5/frontimage',
        'urls': [],
      },
    };
  } else if (q.contains('findGallery(')) {
    data = {
      'findGallery': {'id': '8', 'title': 'Vacances', 'paths': {}},
    };
  } else if (q.contains('findImage(')) {
    data = {
      'findImage': {
        'id': v['id'],
        'title': 'Coucher de soleil',
        'paths': {
          'image': 'http://stash.test/image/${v['id']}/image',
          'thumbnail': 'http://stash.test/image/${v['id']}/thumbnail',
        },
        // Image 5 is a clip: a video shown among the images.
        'visual_files': [
          {'__typename': v['id'] == '5' ? 'VideoFile' : 'ImageFile'},
        ],
      },
    };
  } else if (q.contains('findImages')) {
    data = {
      'findImages': {
        'count': 3,
        'images': [
          for (var i = 0; i < 3; i++)
            {
              'id': '$i',
              'paths': {
                'image': 'http://stash.test/image/$i/image',
                'thumbnail': 'http://stash.test/image/$i/thumbnail',
              },
              'visual_files': [
                {'__typename': i == 1 ? 'VideoFile' : 'ImageFile'},
              ],
            },
        ],
      },
    };
  } else {
    data = {
      'version': {'version': 'v0.28.0'},
    };
  }
  return http.Response.bytes(
    utf8.encode(jsonEncode({'data': data})),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
});

Future<(AppState, FakeFetcher, Directory)> _setup() async {
  final dir = await Directory.systemTemp.createTemp('offline');
  final fetcher = FakeFetcher(dir.path);
  SharedPreferences.setMockInitialValues({});
  final app = AppState(await SharedPreferences.getInstance(), fetcher: fetcher);
  app.repoOverride = StashRepository(
    StashClient(serverUrl: 'http://stash.test', apiKey: 'k', client: _server()),
  );
  return (app, fetcher, dir);
}

void main() {
  test('scene download: progress, persistence and deletion', () async {
    final (app, fetcher, dir) = await _setup();
    final d = app.downloads;
    await d.downloadScene('1');
    final e = d.entry(OfflineKind.scene, '1')!;
    expect(e.title, 'Scène 1');
    expect(e.bytes, 1000);

    final video = fetcher.enqueued.entries.firstWhere((t) => t.value.notify);
    expect(video.value.url, 'http://stash.test/scene/1/stream?apikey=k');
    expect(video.value.path, 'scene_1/video.mkv');
    expect(fetcher.enqueued.length, 2, reason: 'video + cover');

    fetcher.emit(video.key, FileState.running, 0.5);
    await Future<void>.delayed(Duration.zero);
    expect(d.status(e), (FileState.running, 0.5));

    for (final id in fetcher.enqueued.keys) {
      fetcher.emit(id, FileState.done, 1);
    }
    await Future<void>.delayed(Duration.zero);
    expect(d.isDone(e), isTrue);
    expect(File(d.videoPath(e)!).existsSync(), isTrue);

    // A new manager (app restart) finds the download on disk.
    final restarted = DownloadManager(app, FakeFetcher(dir.path));
    await restarted.init();
    final again = restarted.entry(OfflineKind.scene, '1')!;
    expect(restarted.isDone(again), isTrue);
    expect(again.data['title'], 'Scène 1');

    await d.delete(e);
    expect(d.entry(OfflineKind.scene, '1'), isNull);
    expect(Directory('${dir.path}/scene_1').existsSync(), isFalse);
    expect(fetcher.canceled, containsAll(fetcher.enqueued.keys));
  });

  test('group download includes its scenes; deleting removes them', () async {
    final (app, fetcher, _) = await _setup();
    final d = app.downloads;
    expect(await d.downloadGroup('5'), 2);
    final g = d.entry(OfflineKind.group, '5')!;
    expect(g.sceneIds, ['1', '2']);
    expect(d.entry(OfflineKind.scene, '2'), isNotNull);
    expect(d.status(g).$1, FileState.queued);

    for (final id in fetcher.enqueued.keys) {
      fetcher.emit(id, FileState.done, 1);
    }
    await Future<void>.delayed(Duration.zero);
    expect(d.isDone(g), isTrue);

    await d.delete(g);
    expect(d.entries(OfflineKind.scene), isEmpty);
    expect(d.entries(OfflineKind.group), isEmpty);
  });

  test('gallery download keeps image order', () async {
    final (app, fetcher, _) = await _setup();
    final d = app.downloads;
    expect(await d.downloadGallery('8'), 3);
    final g = d.entry(OfflineKind.gallery, '8')!;
    for (final id in fetcher.enqueued.keys) {
      fetcher.emit(id, FileState.done, 1);
    }
    await Future<void>.delayed(Duration.zero);
    expect(d.galleryImages(g).map((p) => p.split('/').last).toList(), [
      '00001.img',
      '00002.clip',
      '00003.img',
    ]);
  });

  test('single image download, listed with the other images', () async {
    final (app, fetcher, dir) = await _setup();
    final d = app.downloads;
    await d.downloadImage('4');
    await d.downloadImage('4'); // already there
    final e = d.entry(OfflineKind.image, '4')!;
    expect(e.title, 'Coucher de soleil');
    // The image, and its thumbnail as the preview.
    expect(
      {for (final t in fetcher.enqueued.values) t.path: t.url},
      {
        'image_4/image.img': 'http://stash.test/image/4/image?apikey=k',
        'image_4/thumb.jpg': 'http://stash.test/image/4/thumbnail?apikey=k',
      },
    );

    for (final id in fetcher.enqueued.keys) {
      fetcher.emit(id, FileState.done, 1);
    }
    await Future<void>.delayed(Duration.zero);
    expect(d.isDone(e), isTrue);
    expect(d.galleryImages(e), ['${dir.path}/image_4/image.img']);
    expect(d.coverPath(e), '${dir.path}/image_4/thumb.jpg');

    await d.delete(e);
    expect(d.entries(OfflineKind.image), isEmpty);
    expect(Directory('${dir.path}/image_4').existsSync(), isFalse);
  });

  testWidgets('the image viewer offers to download the image shown', (
    tester,
  ) async {
    final (app, fetcher, _) =
        await tester.runAsync(_setup) as (AppState, FakeFetcher, Directory);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          home: ImageViewerScreen(
            images: [
              StashImage(id: '4'),
              StashImage(id: '5'),
            ],
            initialIndex: 0,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Télécharger'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cette image'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Télécharger'));
    // Real IO (index file, then the transfer request).
    for (var i = 0; i < 40 && fetcher.enqueued.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
    }
    await tester.pump();
    expect(app.downloads.entry(OfflineKind.image, '4'), isNotNull);
    expect(app.downloads.entry(OfflineKind.image, '5'), isNull);
    expect(fetcher.enqueued, hasLength(2), reason: 'image + thumbnail');
  });

  testWidgets('unreachable server: popup leads to the downloads', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('offline');
    var reachable = false;
    SharedPreferences.setMockInitialValues({'server_url': 'http://stash.test'});
    final app = AppState(
      await SharedPreferences.getInstance(),
      fetcher: FakeFetcher(dir.path),
    );
    app.repoOverride = StashRepository(
      StashClient(
        serverUrl: 'http://stash.test',
        client: MockClient((req) async {
          if (!reachable) throw http.ClientException('Network is unreachable');
          return http.Response(
            jsonEncode({
              'data': {
                'version': {'version': 'v1'},
              },
            }),
            200,
          );
        }),
      ),
    );

    // Like main(): the download index is loaded at startup (real file I/O,
    // which does not advance in the test's fake time).
    await tester.runAsync(app.downloads.init);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: app, child: const StashApp()),
    );
    // Requests fail asynchronously, then the dialog needs a few frames.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(app.offline, isTrue);
    expect(find.text('Hors ligne'), findsOneWidget);

    await tester.tap(find.text('Téléchargements'));
    // Spinners on the home page behind never settle: pump a few frames.
    // The index future completed in real time: let real time run too.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Téléchargements'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Aucun téléchargement.'), findsOneWidget);

    // The periodic probe notices the server is back.
    reachable = true;
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();
    expect(app.offline, isFalse);
    await tester.pump();
    expect(find.text('Connexion au serveur rétablie'), findsOneWidget);
    // Let the snack bar time out.
    await tester.pump(const Duration(seconds: 5));
  });

  test('image clips are kept under a name the viewer plays', () async {
    final (app, fetcher, dir) = await _setup();
    final d = app.downloads;
    await d.downloadImage('5');
    final e = d.entry(OfflineKind.image, '5')!;
    expect(
      [for (final t in fetcher.enqueued.values) t.path],
      ['image_5/image.clip', 'image_5/thumb.jpg'],
    );
    expect(e.cover, 'image_5/thumb.jpg', reason: 'clips have a preview too');

    fetcher.enqueued.clear();
    await d.downloadGallery('8');
    expect(
      [for (final t in fetcher.enqueued.values) t.path],
      [
        'gallery_8/thumb.jpg',
        'gallery_8/00001.img',
        'gallery_8/00002.clip',
        'gallery_8/00003.img',
      ],
    );
    expect(StashImage.offline('1', '/x/00002.clip').isClip, isTrue);
    expect(StashImage.offline('1', '/x/00001.img').isClip, isFalse);
    await dir.delete(recursive: true);
  });

  testWidgets('the viewer plays clips, muted until asked', (tester) async {
    final (app, _, _) =
        await tester.runAsync(_setup) as (AppState, FakeFetcher, Directory);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          home: ImageViewerScreen(
            images: [
              StashImage(id: '4', image: 'http://stash.test/image/4/image'),
              StashImage(
                id: '5',
                image: 'http://stash.test/image/5/image',
                isClip: true,
              ),
            ],
            initialIndex: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.byTooltip('Activer le son'), findsOneWidget);
    await tester.tap(find.byTooltip('Activer le son'));
    await tester.pump();
    expect(find.byTooltip('Couper le son'), findsOneWidget);

    tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(0);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byTooltip('Couper le son'), findsNothing);
  });

  testWidgets('a clip has a bar to seek, ±10 s and play/pause', (tester) async {
    final player = _FakePlayer();
    VideoPlayerPlatform.instance = player;
    final (app, _, _) =
        await tester.runAsync(_setup) as (AppState, FakeFetcher, Directory);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          home: ImageViewerScreen(
            images: [
              StashImage(
                id: '5',
                image: 'http://stash.test/image/5/image',
                isClip: true,
              ),
            ],
            initialIndex: 0,
          ),
        ),
      ),
    );
    // The player opens with real asynchronous work.
    for (
      var i = 0;
      i < 20 && find.byType(VideoPlayer).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('0:12'), findsOneWidget);
    expect(player.playing.values.single, isTrue);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(player.playing.values.single, isFalse);
    expect(find.byTooltip('Lire'), findsOneWidget);

    // ±10 s, within the clip (12 s long).
    await tester.tap(find.byTooltip('Avancer de 10 s'));
    await tester.pump();
    expect(player.seeks.last, const Duration(seconds: 10));
    await tester.tap(find.byTooltip('Avancer de 10 s'));
    await tester.pump();
    expect(player.seeks.last, const Duration(seconds: 12));
    await tester.tap(find.byTooltip('Reculer de 10 s'));
    await tester.pump();
    expect(player.seeks.last, const Duration(seconds: 2));
    await tester.tap(find.byTooltip('Reculer de 10 s'));
    await tester.pump();
    expect(player.seeks.last, Duration.zero);

    // Dragging the bar seeks where it is let go.
    final bar = find.byType(Slider);
    await tester.tapAt(tester.getCenter(bar));
    await tester.pump();
    expect(player.seeks.last.inSeconds, inInclusiveRange(5, 7));

    // Hidden with the rest of the controls.
    await tester.tapAt(const Offset(400, 300));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Slider), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('several images are selected and downloaded at once', (
    tester,
  ) async {
    final (app, fetcher, _) =
        await tester.runAsync(_setup) as (AppState, FakeFetcher, Directory);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: ImagesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sélectionner'));
    await tester.pump();
    expect(find.text('0 sélectionné'), findsOneWidget);

    // A tap selects instead of opening the viewer.
    await tester.tap(find.byType(ImageTile).first);
    await tester.pump();
    expect(find.byType(ImageViewerScreen), findsNothing);
    expect(find.text('1 sélectionné'), findsOneWidget);
    await tester.tap(find.text('Tout'));
    await tester.pump();
    expect(find.text('3 sélectionnés'), findsOneWidget);
    await tester.tap(find.byType(ImageTile).first);
    await tester.pump();

    await tester.tap(find.byTooltip('Télécharger'));
    await tester.pumpAndSettle();
    expect(find.textContaining('les 2 éléments sélectionnés'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Télécharger'));
    for (var i = 0; i < 40 && fetcher.enqueued.length < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(
      [for (final t in fetcher.enqueued.values) t.path],
      [
        'image_1/image.img',
        'image_1/thumb.jpg',
        'image_2/image.img',
        'image_2/thumb.jpg',
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Sélectionner'), findsOneWidget, reason: 'done');
  });

  testWidgets('back leaves the selection, not the page', (tester) async {
    final (app, _, _) =
        await tester.runAsync(_setup) as (AppState, FakeFetcher, Directory);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ImagesScreen())),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sélectionner'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ImagesScreen), findsOneWidget);
    expect(find.byTooltip('Sélectionner'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ImagesScreen), findsNothing);
  });

  group('at launch, a server that does not answer is offline at once', () {
    Future<AppState> app(http.Client client) async {
      SharedPreferences.setMockInitialValues({
        'server_url': 'http://stash.test',
      });
      final app = AppState(await SharedPreferences.getInstance());
      app.repoOverride = StashRepository(
        StashClient(serverUrl: 'http://stash.test', client: client),
      );
      return app;
    }

    test('a proxy answering 502 for a stopped Stash', () async {
      final a = await app(MockClient((_) async => http.Response('', 502)));
      await a.checkServer();
      expect(a.offline, isTrue);
    });

    testWidgets('a server that never answers, after 8 s', (tester) async {
      final a = await app(MockClient((_) => Completer<http.Response>().future));
      a.checkServer().ignore();
      await tester.pump(const Duration(seconds: 7));
      expect(a.offline, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(a.offline, isTrue);
      a.dispose(); // stops probing the server
    });
  });

  testWidgets('offline behind the lock screen: the popup comes after it', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('offline');
    SharedPreferences.setMockInitialValues({
      'server_url': 'http://stash.test',
      'auto_update': false,
    });
    final prefs = await SharedPreferences.getInstance();
    await AppState(prefs).lock.setPassword('1234');
    final app = AppState(prefs, fetcher: FakeFetcher(dir.path));
    expect(app.lock.locked, isTrue);
    app.repoOverride = StashRepository(
      StashClient(
        serverUrl: 'http://stash.test',
        client: MockClient(
          (_) async => throw http.ClientException('Network is unreachable'),
        ),
      ),
    );
    await tester.runAsync(app.downloads.init);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: app, child: const StashApp()),
    );
    await app.checkServer();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(app.offline, isTrue);
    expect(find.text('Hors ligne'), findsNothing, reason: 'locked');

    app.lock.unlock('1234');
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Hors ligne'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    app.dispose(); // stops probing the server
  });

  testWidgets('downloads: a tab per kind, cards with previews and actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (app, fetcher, _) =
        await tester.runAsync(_setup) as (AppState, FakeFetcher, Directory);
    final d = app.downloads;
    await tester.runAsync(() async {
      await d.downloadScene('1');
      await d.downloadImage('4');
    });
    // The image is done, the scene still downloading.
    for (final t in fetcher.enqueued.entries) {
      if (t.value.path.startsWith('image_')) {
        fetcher.emit(t.key, FileState.done, 1);
      } else {
        fetcher.emit(t.key, FileState.running, 0.5);
      }
    }
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: DownloadsScreen()),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(find.text('Scènes (1)'), findsOneWidget);
    expect(find.text('Images (1)'), findsOneWidget);
    expect(find.text('Groupes (0)'), findsNothing, reason: 'empty kinds hide');
    expect(find.byType(DownloadCard), findsOneWidget);
    expect(find.text('Scène 1'), findsOneWidget);
    expect(find.textContaining('Téléchargement · 50 %'), findsOneWidget);

    // Not openable yet: a tap offers the actions.
    await tester.tap(find.byType(DownloadCard));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Images (1)'));
    await tester.pumpAndSettle();
    final cover = tester.widget<NetImage>(
      find.descendant(
        of: find.byType(DownloadCard),
        matching: find.byType(NetImage),
      ),
    );
    expect(cover.url, endsWith('image_4/thumb.jpg'));
  });
}
