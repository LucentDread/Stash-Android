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
import 'package:stash_android/models/scene_filter.dart';
import 'package:stash_android/screens/home_screen.dart';
import 'package:stash_android/services/app_lock.dart';
import 'package:stash_android/services/app_state.dart';
import 'package:stash_android/services/updater.dart';
import 'package:stash_android/widgets/app_gate.dart';

Map<String, dynamic> _release(
  String tag, {
  List<String> apks = const ['Stash-x-arm64-v8a.apk'],
  bool draft = false,
}) => {
  'tag_name': tag,
  'draft': draft,
  'prerelease': false,
  'body': '- Nouveauté de $tag\n  sur deux lignes.\n- Autre',
  'assets': [
    for (final a in apks)
      {
        'name': a,
        'size': 1234,
        'browser_download_url': 'https://example.test/$tag/$a',
      },
  ],
};

Updater _updater(List<Map<String, dynamic>> releases, String current) =>
    Updater(
      currentVersion: () async => current,
      client: MockClient((req) async {
        expect(req.url.path, '/repos/LucentDread/Stash-Android/releases');
        return http.Response.bytes(utf8.encode(jsonEncode(releases)), 200);
      }),
    );

void main() {
  group('lock', () {
    test('password is hashed, checked, and locks the next launch', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final lock = AppLock(prefs);
      expect(lock.enabled, isFalse);
      expect(lock.locked, isFalse);

      await lock.setPassword('secret');
      expect(lock.locked, isFalse, reason: 'stays open after creation');
      expect(prefs.getKeys().any((k) => prefs.get(k) == 'secret'), isFalse);
      expect(lock.check('secret'), isTrue);
      expect(lock.check('Secret'), isFalse);

      final next = AppLock(prefs);
      expect(next.locked, isTrue);
      expect(next.unlock('nope'), isFalse);
      expect(next.locked, isTrue);
      expect(next.unlock('secret'), isTrue);
      expect(next.locked, isFalse);

      await next.removePassword();
      expect(AppLock(prefs).locked, isFalse);
    });

    test('locks again after the chosen time in the background', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var now = DateTime(2026);
      final lock = AppLock(prefs, clock: () => now);
      await lock.setPassword('1234');

      void away(Duration d, {bool pip = false}) {
        lock.didChangeAppLifecycleState(AppLifecycleState.inactive);
        if (!pip) lock.didChangeAppLifecycleState(AppLifecycleState.hidden);
        if (!pip) lock.didChangeAppLifecycleState(AppLifecycleState.paused);
        now = now.add(d);
        lock.didChangeAppLifecycleState(AppLifecycleState.resumed);
      }

      // Default: one minute.
      away(const Duration(seconds: 30));
      expect(lock.locked, isFalse);
      away(const Duration(minutes: 2), pip: true);
      expect(lock.locked, isFalse, reason: 'small window, never left');
      away(const Duration(minutes: 2));
      expect(lock.locked, isTrue);

      lock.unlock('1234');
      lock.delayMinutes = null;
      away(const Duration(hours: 5));
      expect(lock.locked, isFalse, reason: 'only at launch');

      lock.delayMinutes = 0;
      away(Duration.zero);
      expect(lock.locked, isTrue);
    });

    testWidgets('lock page covers the app until the password is given', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await AppLock(prefs).setPassword('abcd');
      prefs.setBool('auto_update', false);
      final app = AppState(prefs);
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            builder: (context, child) =>
                AppGate(navigatorKey: navigatorKey, child: child!),
            home: const Scaffold(body: Text('Contenu privé')),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Stash est verrouillé'), findsOneWidget);
      expect(find.text('Contenu privé'), findsNothing);

      // Back does not reveal the app.
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Stash est verrouillé'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Mot de passe incorrect'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'abcd');
      await tester.tap(find.text('Déverrouiller'));
      await tester.pumpAndSettle();
      expect(find.text('Stash est verrouillé'), findsNothing);
      expect(find.text('Contenu privé'), findsOneWidget);
    });
  });

  group('updates', () {
    test('lists newer releases with an APK, newest first', () async {
      final info = await _updater([
        _release('v1.10.0', apks: []), // APK not attached yet
        _release(
          'v1.9.1',
          apks: ['Stash-1.9.1-x86.apk', 'Stash-1.9.1-arm64-v8a.apk'],
        ),
        _release('v2.0.0', draft: true),
        _release('v1.9.0'),
        _release('v1.8.0'),
        _release('v1.7.1'),
      ], '1.8.0').check();

      expect([for (final r in info!.newer) r.version], ['1.9.1', '1.9.0']);
      expect(
        info.latest.apkUrl,
        'https://example.test/v1.9.1/Stash-1.9.1-arm64-v8a.apk',
      );
      expect(info.latest.apkSize, 1234);
    });

    test('up to date: nothing to offer', () async {
      expect(
        await _updater([
          _release('v1.9.0'),
          _release('v1.8.0'),
        ], '1.9.0').check(),
        isNull,
      );
    });

    test('versions compare by number, not text', () {
      final v = Updater.parseVersion;
      expect(Updater.compareVersions(v('1.10.0')!, v('1.9.9')!), 1);
      expect(Updater.compareVersions(v('1.8.0')!, v('1.8.0+12')!), 0);
      expect(v('main'), isNull);
    });

    test('release notes become list items', () {
      expect(Updater.noteItems('- Un\n  suite.\n\n- Deux\n'), [
        'Un suite.',
        'Deux',
      ]);
    });

    test('download writes the APK and reports progress', () async {
      final dir = await Directory.systemTemp.createTemp('update');
      addTearDown(() => dir.delete(recursive: true));
      final bytes = List.generate(5000, (i) => i % 256);
      final updater = Updater(
        client: MockClient.streaming((req, _) async {
          expect(req.url.toString(), 'https://example.test/a.apk');
          return http.StreamedResponse(
            Stream.fromIterable([bytes.sublist(0, 2000), bytes.sublist(2000)]),
            200,
            contentLength: bytes.length,
          );
        }),
      );
      final progress = <double?>[];
      final file = await updater.download(
        const Release(
          version: '1.9.0',
          notes: '',
          apkUrl: 'https://example.test/a.apk',
        ),
        into: dir,
        onProgress: progress.add,
      );
      expect(file.path, endsWith('/updates/Stash-1.9.0.apk'));
      expect(await file.readAsBytes(), bytes);
      expect(progress, [0.4, 1.0]);
    });
  });

  group('home', () {
    Future<AppState> app(WidgetTester tester, List<String> homeIds) async {
      SharedPreferences.setMockInitialValues({});
      final app = AppState(await SharedPreferences.getInstance());
      app.repoOverride = StashRepository(
        StashClient(
          serverUrl: 'http://stash.test',
          client: MockClient((req) async {
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            final page = body['variables']['filter']['page'] as int;
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'data': {
                    'findScenes': {
                      'count': 14,
                      'scenes': [
                        for (var i = 0; i < (page == 1 ? 12 : 2); i++)
                          {
                            'id': '$page-$i',
                            'title': 'Scène $page-$i',
                            'paths': <String, dynamic>{},
                          },
                      ],
                    },
                  },
                }),
              ),
              200,
            );
          }),
        ),
      );
      for (final (id, name) in [('a', 'Hors groupe'), ('b', 'Favoris')]) {
        app.saveView(SavedView(id: id, name: name, filter: SceneFilter()));
      }
      for (final id in homeIds) {
        app.setHomeView(id, true);
      }
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: const MaterialApp(home: HomeTab()),
        ),
      );
      await tester.pump();
      await tester.pump();
      return app;
    }

    testWidgets('one view names the page', (tester) async {
      await app(tester, ['b']);
      expect(find.text('Favoris'), findsOneWidget);
      expect(find.text('Accueil'), findsNothing);
      expect(find.byTooltip('Accueil par défaut'), findsOneWidget);
    });

    testWidgets('several views are stacked under "Accueil"', (tester) async {
      tester.view.physicalSize = const Size(1080, 16000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await app(tester, ['a', 'b']);
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.byTooltip('Accueil par défaut'), findsOneWidget);
      expect(find.textContaining('Hors groupe'), findsOneWidget);
      expect(find.textContaining('Favoris'), findsOneWidget);
      expect(find.text('Voir tout'), findsNWidgets(2));

      final more = find.text('Afficher plus (2)');
      expect(more, findsNWidgets(2));
      await tester.tap(more.first);
      await tester.pump();
      await tester.pump();
      expect(find.text('Afficher plus (2)'), findsOneWidget);
      expect(find.text('Scène 2-1'), findsOneWidget);
    });
  });
}
