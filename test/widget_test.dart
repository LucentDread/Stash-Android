import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/main.dart';
import 'package:stash_android/services/app_state.dart';

void main() {
  testWidgets('shows the setup screen when no server is configured',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(prefs),
      child: const StashApp(),
    ));
    expect(find.text('Adresse du serveur'), findsOneWidget);

    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(find.text('Saisissez l\'adresse du serveur.'), findsOneWidget);
  });
}
