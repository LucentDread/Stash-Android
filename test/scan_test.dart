import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/api/stash_client.dart';
import 'package:stash_android/api/stash_repository.dart';
import 'package:stash_android/main.dart';
import 'package:stash_android/services/app_state.dart';
import 'package:stash_android/services/scan_tracker.dart';

/// Fake Stash: scan defaults, a scan job going through [jobStates], and
/// empty lists for everything else.
class FakeStash {
  FakeStash(this.jobStates);
  final List<Map<String, dynamic>?> jobStates;
  final requests = <Map<String, dynamic>>[];
  int _poll = 0;

  int count(String op) =>
      requests.where((r) => (r['query'] as String).contains(op)).length;

  http.Client get client => MockClient((req) async {
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    requests.add(body);
    final q = body['query'] as String;
    Object? data;
    if (q.contains('configuration')) {
      data = {
        'configuration': {
          'defaults': {
            'scan': {
              'rescan': false,
              'scanGenerateCovers': true,
              'scanGeneratePreviews': true,
              'scanGenerateImagePhashes': null,
            },
          },
        },
      };
    } else if (q.contains('metadataScan')) {
      data = {'metadataScan': '7'};
    } else if (q.contains('findJob')) {
      final i = _poll < jobStates.length ? _poll : jobStates.length - 1;
      _poll++;
      data = {'findJob': jobStates[i]};
    } else if (q.contains('findScenes')) {
      data = {
        'findScenes': {'count': 0, 'scenes': []},
      };
    } else {
      data = {};
    }
    return http.Response(jsonEncode({'data': data}), 200);
  });
}

Map<String, dynamic> job(String status, {double? progress, String? task}) => {
  'id': '7',
  'status': status,
  'description': 'Scanning...',
  'progress': progress,
  'subTasks': [?task],
  'error': null,
};

Future<AppState> appWith(FakeStash fake) async {
  SharedPreferences.setMockInitialValues({'server_url': 'http://stash.test'});
  final app = AppState(await SharedPreferences.getInstance());
  app.repoOverride = StashRepository(
    StashClient(serverUrl: 'http://stash.test', client: fake.client),
  );
  return app;
}

void main() {
  testWidgets('tracker follows the job and refreshes data at the end', (
    tester,
  ) async {
    final fake = FakeStash([
      job('RUNNING', task: 'Walking directory tree'),
      job('RUNNING', progress: 0.42, task: 'Scanning /data/films/clip.mp4'),
      job('FINISHED', progress: 1),
    ]);
    final app = await appWith(fake);
    final scan = ScanTracker(
      app,
      pollInterval: const Duration(seconds: 1),
      doneDisplay: const Duration(seconds: 4),
    );

    await tester.runAsync(scan.start);
    expect(scan.phase, ScanPhase.running);
    // Stash's default scan options are sent, without null values.
    expect(fake.requests[1]['variables']['input'], {
      'rescan': false,
      'scanGenerateCovers': true,
      'scanGeneratePreviews': true,
    });
    expect(scan.currentItem, 'Walking directory tree');

    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    expect(scan.job?.progress, 0.42);
    expect(scan.currentItem, '/data/films/clip.mp4');

    final before = app.dataVersion;
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    expect(scan.phase, ScanPhase.finished);
    expect(app.dataVersion, before + 1);
    scan.dismiss();
    expect(scan.phase, ScanPhase.idle);
    scan.dispose();
  });

  test('a job dropped by Stash counts as finished', () async {
    final fake = FakeStash([null]);
    final app = await appWith(fake);
    final scan = ScanTracker(app, doneDisplay: Duration.zero);
    await scan.start();
    expect(scan.phase, ScanPhase.finished);
    scan.dispose();
  });

  testWidgets('banner shows progress over pushed pages; lists reload after', (
    tester,
  ) async {
    final fake = FakeStash([
      job('RUNNING', progress: 0.42, task: 'Scanning /data/films/clip.mp4'),
    ]);
    final app = await appWith(fake);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: app, child: const StashApp()),
    );
    await tester.pump();

    // Open the scenes tab, then push a page on top of the shell.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Scènes'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final scenesQueries = fake.count('findScenes');
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Page poussée')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(app.scan.start);
    await tester.pump();
    expect(find.text('Page poussée'), findsOneWidget);
    expect(find.text('Scan de la bibliothèque · 42 %'), findsOneWidget);
    expect(find.text('clip.mp4'), findsOneWidget);
    expect(find.text('/data/films'), findsOneWidget);

    // End of scan: the banner says so and lists below reload in place.
    app.scan.dispose();
    navigator.pop();
    await tester.pumpAndSettle();
    app.refreshData();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(fake.count('findScenes'), greaterThan(scenesQueries));
  });
}
