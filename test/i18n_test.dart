import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/l10n/l10n.dart';
import 'package:stash_android/main.dart';
import 'package:stash_android/models/scene_filter.dart';
import 'package:stash_android/services/app_state.dart';
import 'package:stash_android/utils/format.dart';

Future<AppState> _app([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  return AppState(await SharedPreferences.getInstance());
}

List<String> _barLabels(WidgetTester tester) => [
  for (final d in tester.widgetList<NavigationDestination>(
    find.byType(NavigationDestination),
  ))
    d.label,
];

void main() {
  tearDown(() {
    systemLanguage = () => 'fr';
    tr = lookupAppLocalizations(const Locale('fr'));
  });

  test('every language has every text, with the same placeholders', () {
    Map<String, dynamic> arb(String lang) =>
        jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
            as Map<String, dynamic>;
    final keys = arb('en').keys.where((k) => !k.startsWith('@')).toSet();
    final names = RegExp(r'(?<![\w=])\{(\w+)[},]');
    for (final lang in appLanguages) {
      final t = arb(lang);
      expect(
        t.keys.where((k) => !k.startsWith('@')).toSet(),
        keys,
        reason: lang,
      );
      for (final k in keys) {
        Set<String> ph(String s) =>
            names.allMatches(s).map((m) => m[1]!).toSet();
        expect(
          ph(t[k] as String),
          ph(arb('en')[k] as String),
          reason: '$lang $k',
        );
      }
    }
  });

  test('the language follows the device, or the setting', () async {
    systemLanguage = () => 'de';
    final app = await _app();
    expect(app.language, isNull);
    expect(app.effectiveLanguage, 'de');
    expect(ViewKind.performers.label, 'Darsteller');

    app.language = 'es';
    expect(tr.localeName, 'es');
    expect(ViewKind.scenes.label, 'Escenas');
    app.language = null;
    expect(tr.localeName, 'de');

    // A device language the app does not speak falls back to English.
    systemLanguage = () => 'en';
    expect((await _app({'language': 'xx'})).effectiveLanguage, 'en');
    expect(ViewKind.galleries.label, 'Galleries');
  });

  test('plurals follow each language', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final fr = lookupAppLocalizations(const Locale('fr'));
    final it = lookupAppLocalizations(const Locale('it'));
    expect(en.countScenes(1), '1 scene');
    expect(en.countScenes(0), '0 scenes');
    expect(fr.countScenes(0), '0 scène');
    expect(fr.countScenes(2), '2 scènes');
    expect(it.countScenes(3), '3 scene');
    expect(en.lockAfterMinutes(1), 'After 1 minute in the background');
    expect(fr.lockAfterMinutes(5), 'Après 5 minutes en arrière-plan');
  });

  test('filter descriptions agree with the listed kind', () {
    final f = SceneFilter(played: true, organized: false);
    expect(f.describe(), ['Non organisées', 'Déjà vues']);
    expect(SceneFilter(organized: true).describe(ViewKind.studios), [
      'Organisé',
    ]);
    tr = lookupAppLocalizations(const Locale('en'));
    expect(f.describe(), ['Not organized', 'Watched']);
  });

  test('nouns inside sentences keep their capital in German only', () {
    expect(inSentence(ViewKind.scenes.label), 'scènes');
    tr = lookupAppLocalizations(const Locale('de'));
    expect(inSentence(ViewKind.scenes.label), 'Szenen');
    expect(
      tr.noFilterAll(inSentence(ViewKind.scenes.label)),
      'Ohne Filter (alle Szenen)',
    );
  });

  testWidgets('changing the language relabels the open pages at once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final app = await _app({
      'server_url': 'http://stash.test',
      'auto_update': false,
      'language': 'en',
    });
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: app, child: const StashApp()),
    );
    await tester.pump();
    expect(_barLabels(tester), [
      'Home',
      'Scenes',
      'Groups',
      'Performers',
      'More',
    ]);

    await tester.tap(find.text('More').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('App language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(app.language, 'de');
    // Still on the settings page, now in German.
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('App-Sprache'), findsOneWidget);
    expect(find.text('Passwort erstellen'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Gespeicherte Ansichten'), findsOneWidget);
    expect(_barLabels(tester), [
      'Startseite',
      'Szenen',
      'Gruppen',
      'Darsteller',
      'Mehr',
    ]);
    // Pages that do not watch the app state are redrawn too.
    await tester.tap(find.text('Tabs'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Wählen Sie bis zu 4'), findsOneWidget);
    app.language = 'it';
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Seleziona fino a 4'), findsOneWidget);
    expect(find.text('Scheda'), findsWidgets);
    app.language = 'de';
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Material's own texts follow too.
    expect(
      MaterialLocalizations.of(tester.element(find.byType(NavigationBar)))
          .okButtonLabel,
      'OK',
    );
    expect(
      Localizations.localeOf(tester.element(find.byType(NavigationBar))),
      const Locale('de'),
    );
  });
}
