import 'dart:async';
import 'dart:ui';

import 'package:stash_android/l10n/l10n.dart';

/// The tests were written against the French texts: the device language
/// is French unless a test says otherwise.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  systemLanguage = () => 'fr';
  tr = lookupAppLocalizations(const Locale('fr'));
  await testMain();
}
