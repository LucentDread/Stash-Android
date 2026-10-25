import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../screens/update_dialog.dart';
import '../services/app_lock.dart';
import '../services/app_state.dart';
import '../services/updater.dart';

/// Sits above the navigator: shows the lock screen when the app is locked
/// (as a page the back button cannot close), then looks for updates once
/// per launch.
class AppGate extends StatefulWidget {
  const AppGate({
    super.key,
    required this.navigatorKey,
    required this.child,
    this.updater,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  /// Replaced in tests.
  final Updater? updater;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  late final AppState _app = context.read<AppState>();
  AppLock get _lock => _app.lock;
  Route<void>? _lockRoute;
  bool _updateChecked = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lock);
    _lock.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _lock.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(_lock);
    super.dispose();
  }

  void _sync() {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null || !mounted) return;
    if (_lock.locked && _lockRoute == null) {
      final route = PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const LockScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: const Duration(milliseconds: 150),
      );
      _lockRoute = route;
      navigator.push(route);
    } else if (!_lock.locked && _lockRoute != null) {
      navigator.removeRoute(_lockRoute!);
      _lockRoute = null;
    }
    // Repaint: the cover hiding the first frame goes away.
    setState(() {});
    if (!_lock.locked) _checkUpdates();
  }

  void _checkUpdates() {
    if (_updateChecked || !_app.autoUpdate) return;
    _updateChecked = true;
    // Let the home page load first.
    _updateTimer = Timer(const Duration(seconds: 3), () {
      final ctx = widget.navigatorKey.currentState?.overlay?.context;
      if (ctx == null || !ctx.mounted || _lock.locked) return;
      checkForUpdates(ctx, updater: widget.updater);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        // Until the lock page is pushed (after the first frame), nothing of
        // the app may show.
        if (_lock.locked && _lockRoute == null)
          const ColoredBox(color: Colors.black),
      ],
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _password = TextEditingController();
  final _focus = FocusNode();
  bool _wrong = false;
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = context.read<AppState>().lock.unlock(_password.text);
    if (!ok) {
      setState(() => _wrong = true);
      _password.clear();
      // Ready for another try without tapping the field again.
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // Back leaves the app instead of revealing it.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/branding/logo.png', height: 72),
                    const SizedBox(height: 16),
                    Text(
                      'Stash est verrouillé',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _password,
                      focusNode: _focus,
                      autofocus: true,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      onChanged: (_) {
                        if (_wrong) setState(() => _wrong = false);
                      },
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        border: const OutlineInputBorder(),
                        errorText: _wrong ? 'Mot de passe incorrect' : null,
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Afficher' : 'Masquer',
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.lock_open),
                        label: const Text('Déverrouiller'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
