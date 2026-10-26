import 'dart:ui';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Strings in the app's current language (see [AppState.language]).
///
/// A global rather than `AppLocalizations.of(context)` so models, services
/// and notifications, which have no context, speak the same language.
AppLocalizations tr = lookupAppLocalizations(const Locale('en'));

/// Languages the app is translated into, in the order they are offered.
const appLanguages = ['en', 'fr', 'de', 'it', 'es'];

/// Each language's name, in that language.
const languageNames = {
  'en': 'English',
  'fr': 'Français',
  'de': 'Deutsch',
  'it': 'Italiano',
  'es': 'Español',
};

/// The device's first language the app speaks, else English. Replaceable
/// in tests.
String Function() systemLanguage = () {
  for (final l in PlatformDispatcher.instance.locales) {
    if (appLanguages.contains(l.languageCode)) return l.languageCode;
  }
  return 'en';
};
