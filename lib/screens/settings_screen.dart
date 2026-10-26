import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/app_lock.dart';
import '../services/app_state.dart';
import '../services/system_bridge.dart';
import 'update_dialog.dart';

/// More > Application > Settings: language, popup player, privacy,
/// password, updates.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _password(BuildContext context, _PasswordMode mode) async {
    final lock = context.read<AppState>().lock;
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _PasswordDialog(mode: mode, lock: lock),
    );
    if (result == null) return;
    if (mode == _PasswordMode.remove) {
      await lock.removePassword();
      messenger.showSnackBar(SnackBar(content: Text(tr.passwordRemoved)));
    } else {
      await lock.setPassword(result);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            mode == _PasswordMode.create
                ? tr.passwordCreated
                : tr.passwordChanged,
          ),
        ),
      );
    }
  }

  Future<void> _pickLanguage(BuildContext context, AppState app) async {
    final current = app.language;
    final picked = await showDialog<(String?,)>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr.language),
        children: [
          for (final l in [null, ...appLanguages])
            ListTile(
              leading: Icon(
                l == current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(
                l == null
                    ? tr.systemLanguage(languageNames[systemLanguage()]!)
                    : languageNames[l]!,
              ),
              onTap: () => Navigator.pop(context, (l,)),
            ),
        ],
      ),
    );
    if (picked != null) app.language = picked.$1;
  }

  Future<void> _pickDelay(BuildContext context, AppLock lock) async {
    final current = lock.delayMinutes;
    final picked = await showDialog<(int?,)>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr.askPasswordAgain),
        children: [
          for (final d in AppLock.delays)
            ListTile(
              leading: Icon(
                d == current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(AppLock.describeDelay(d)),
              onTap: () => Navigator.pop(context, (d,)),
            ),
        ],
      ),
    );
    if (picked != null) lock.delayMinutes = picked.$1;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lock = app.lock;
    return Scaffold(
      appBar: AppBar(title: Text(tr.settings)),
      body: ListenableBuilder(
        listenable: lock,
        builder: (context, _) => ListView(
          children: [
            _Header(tr.language),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(tr.appLanguage),
              subtitle: Text(
                app.language == null
                    ? tr.systemLanguage(languageNames[systemLanguage()]!)
                    : languageNames[app.effectiveLanguage]!,
              ),
              onTap: () => _pickLanguage(context, app),
            ),
            const Divider(),
            _Header(tr.playbackHeader),
            SwitchListTile(
              secondary: const Icon(Icons.picture_in_picture_alt_outlined),
              title: Text(tr.popupPlayer),
              subtitle: Text(tr.popupPlayerSubtitle),
              value: app.popupPlayer,
              onChanged: (v) => app.popupPlayer = v,
            ),
            const Divider(),
            _Header(tr.privacyHeader),
            SwitchListTile(
              secondary: const Icon(Icons.visibility_off_outlined),
              title: Text(tr.hideInRecents),
              subtitle: Text(tr.hideInRecentsSubtitle),
              value: app.hideInRecents,
              onChanged: (v) {
                app.hideInRecents = v;
                SystemBridge.instance.setSecure(v);
              },
            ),
            if (!lock.enabled)
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(tr.createPassword),
                subtitle: Text(tr.createPasswordSubtitle),
                onTap: () => _password(context, _PasswordMode.create),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.lock),
                title: Text(tr.changePassword),
                onTap: () => _password(context, _PasswordMode.change),
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text(tr.askPasswordAgain),
                subtitle: Text(AppLock.describeDelay(lock.delayMinutes)),
                onTap: () => _pickDelay(context, lock),
              ),
              ListTile(
                leading: const Icon(Icons.lock_open),
                title: Text(tr.removePassword),
                onTap: () => _password(context, _PasswordMode.remove),
              ),
            ],
            const Divider(),
            _Header(tr.updatesHeader),
            SwitchListTile(
              secondary: const Icon(Icons.update),
              title: Text(tr.checkAtStartup),
              subtitle: Text(tr.checkAtStartupSubtitle),
              value: app.autoUpdate,
              onChanged: (v) => app.autoUpdate = v,
            ),
            ListTile(
              leading: const Icon(Icons.system_update),
              title: Text(tr.checkForUpdate),
              onTap: () => checkForUpdates(context, manual: true),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PasswordMode { create, change, remove }

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.mode, required this.lock});
  final _PasswordMode mode;
  final AppLock lock;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _currentError, _newError, _confirmError;

  bool get _askCurrent => widget.mode != _PasswordMode.create;
  bool get _askNew => widget.mode != _PasswordMode.remove;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _currentError = _askCurrent && !widget.lock.check(_current.text)
          ? tr.wrongPassword
          : null;
      _newError = _askNew && _new.text.length < 4 ? tr.passwordTooShort : null;
      _confirmError = _askNew && _confirm.text != _new.text
          ? tr.passwordsDiffer
          : null;
    });
    if (_currentError == null && _newError == null && _confirmError == null) {
      Navigator.pop(context, _askNew ? _new.text : '');
    }
  }

  Widget _field(
    TextEditingController c,
    String label,
    String? error, {
    bool autofocus = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      autofocus: autofocus,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => _submit(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final (title, action) = switch (widget.mode) {
      _PasswordMode.create => (tr.createPassword, tr.create),
      _PasswordMode.change => (tr.changePassword, tr.edit),
      _PasswordMode.remove => (tr.removePassword, tr.delete),
    };
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_askCurrent)
              _field(
                _current,
                tr.currentPassword,
                _currentError,
                autofocus: true,
              ),
            if (_askNew) ...[
              _field(_new, tr.newPassword, _newError, autofocus: !_askCurrent),
              _field(_confirm, tr.confirmation, _confirmError),
            ],
            if (widget.mode == _PasswordMode.create)
              Text(tr.forgottenPasswordHint),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(action)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
