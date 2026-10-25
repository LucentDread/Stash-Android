import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/models/models.dart';
import 'package:stash_android/services/app_state.dart';
import 'package:stash_android/widgets/cards.dart';

Scene _scene(Map<String, dynamic> extra) => Scene.fromJson({
  'id': '1',
  'created_at': '2024-05-01T10:00:00Z',
  'paths': <String, dynamic>{},
  'files': [
    {
      'path': '/data/videos/clip.mp4',
      'duration': 600,
      'width': 1920,
      'height': 1080,
      'size': 2000000000,
      'video_codec': 'h264',
      'frame_rate': 29.97,
    },
  ],
  ...extra,
});

const _long = 'Un titre vraiment très long qui prend deux lignes sur la carte';

void main() {
  final cases = <String, Scene>{
    'short title, studio, tags, performers': _scene({
      'title': 'Court',
      'studio': {'id': '1', 'name': 'Studio'},
      'date': '2024-01-01',
      'tags': [
        {'id': '1', 'name': 'Plage'},
      ],
      'performers': [
        {'id': '1', 'name': 'Alice'},
      ],
    }),
    'long title with studio': _scene({
      'title': _long,
      'studio': {'id': '1', 'name': 'Studio'},
      'tags': [
        {'id': '1', 'name': 'Intérieur'},
      ],
    }),
    'long title without studio': _scene({'title': _long}),
    'bare scene': _scene({'title': 'Seul'}),
  };

  for (final width in [150.0, 194.0, 300.0]) {
    for (final entry in cases.entries) {
      testWidgets('card fills its space: ${entry.key}, ${width}px', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        late double small;
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => AppState(prefs),
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  small = CardText.smallLine(context);
                  return Center(
                    child: SizedBox(
                      width: width,
                      height: SceneCard.heightFor(context, width),
                      child: SceneCard(scene: entry.value),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        // No overflow errors.
        expect(tester.takeException(), isNull);

        // The detail area shows at least one line and leaves less than a
        // line unused.
        final fill = tester.renderObject<RenderBox>(find.byType(LayoutBuilder));
        final rich = tester.renderObject<RenderBox>(
          find.byWidgetPredicate((w) => w is Text && w.textSpan != null),
        );
        expect(fill.size.height, greaterThanOrEqualTo(small));
        expect(fill.size.height - rich.size.height, lessThan(small));
      });
    }
  }
}
