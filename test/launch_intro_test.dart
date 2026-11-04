import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stash_android/widgets/launch_intro.dart';

void main() {
  Widget app({bool logoShown = true}) => LaunchIntro(
    logoShown: logoShown,
    child: const MaterialApp(home: Scaffold(body: Text('the app'))),
  );

  Rect logo(WidgetTester tester) => tester.getRect(find.byType(Image));

  testWidgets('starts like the launch screen, ends logo + name, then fades', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());

    // First frame: the logo where Android's launch screen drew it.
    final first = logo(tester);
    expect(first.size.width, closeTo(LaunchIntro.logoSize.width, 0.01));
    expect(first.center.dx, closeTo(960 + LaunchIntro.logoOffset.dx, 0.01));
    expect(first.center.dy, closeTo(540 + LaunchIntro.logoOffset.dy, 0.01));
    expect(find.text('the app'), findsOneWidget, reason: 'built beneath');

    // Partway: the logo has grown and moved left, the name is out.
    await tester.pump(LaunchIntro.duration * 0.7);
    final later = logo(tester);
    expect(later.height, closeTo(72, 0.5));
    expect(later.center.dx, lessThan(first.center.dx - 50));
    final name = tester.getRect(find.text('Stash'));
    expect(name.left, greaterThan(later.right));
    // Logo and name centered together.
    expect((later.left + name.right) / 2, closeTo(960, 2));

    // Then gone: the app alone.
    await tester.pump(LaunchIntro.duration);
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.text('Stash'), findsNothing);
    expect(find.text('the app'), findsOneWidget);
  });

  testWidgets('from Android 12, the logo appears first', (tester) async {
    await tester.pumpWidget(app(logoShown: false));
    // The logo's own (the nearest; the other fades the whole out).
    final opacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.byType(Image), matching: find.byType(Opacity))
          .first,
    );
    expect(opacity.opacity, 0);
    await tester.pump(LaunchIntro.duration);
    await tester.pump();
  });

  testWidgets('no animation when the device asks for none', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: app(),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.text('the app'), findsOneWidget);
  });
}
