import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/api/stash_repository.dart';
import 'package:stash_android/models/models.dart';
import 'package:stash_android/services/app_state.dart';
import 'package:stash_android/widgets/paged_grid.dart';

/// Behaves like Stash's random sort: plain "random" reshuffles on every
/// request, `random_<seed>` always gives the same order for a seed.
class FakeRandomServer {
  FakeRandomServer(this.total);
  final int total;
  final sorts = <String?>[];

  Future<ResultPage<int>> fetch(ListQuery q) async {
    sorts.add(q.sort);
    final ids = List.generate(total, (i) => i);
    final seed = q.sort == 'random'
        ? Random().nextInt(1 << 30)
        : int.parse(q.sort!.substring('random_'.length));
    ids.shuffle(Random(seed));
    final start = (q.page - 1) * q.perPage;
    return ResultPage(ids.skip(start).take(q.perPage).toList(), total);
  }
}

Future<List<int>> _loadAll(
  WidgetTester tester,
  FakeRandomServer server, {
  Key? key,
}) async {
  final shown = <int>[];
  SharedPreferences.setMockInitialValues({});
  final app = AppState(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: app,
      child: MaterialApp(
        home: Scaffold(
          body: PagedGrid<int>(
            key: key,
            fetch: server.fetch,
            sortOptions: const [SortOption('random')],
            initialSort: 'random',
            itemKey: (i) => i,
            maxCrossAxisExtent: 1000,
            childAspectRatio: 20,
            itemBuilder: (_, i, _, all) {
              if (all.length > shown.length) {
                shown
                  ..clear()
                  ..addAll(all);
              }
              return Text('item $i');
            },
          ),
        ),
      ),
    ),
  );
  // Scroll to the end until every page is loaded.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.drag(find.byType(GridView), const Offset(0, -3000));
  }
  await tester.pump();
  return shown;
}

void main() {
  testWidgets('random sort pages share one seed: no duplicates, no gaps', (
    tester,
  ) async {
    final server = FakeRandomServer(100);
    final shown = await _loadAll(tester, server);

    expect(server.sorts.length, 3, reason: '100 items, 40 per page');
    expect(server.sorts.toSet().length, 1, reason: 'same seed for all pages');
    expect(server.sorts.first, startsWith('random_'));
    expect(shown.length, 100);
    expect(shown.toSet().length, 100);
  });

  testWidgets('a reload draws a new order', (tester) async {
    final server = FakeRandomServer(10);
    await _loadAll(tester, server);
    await tester.fling(find.byType(GridView), const Offset(0, 600), 2000);
    await tester.pumpAndSettle();
    expect(server.sorts.length, 2);
    expect(server.sorts[0], isNot(server.sorts[1]));
  });
}
