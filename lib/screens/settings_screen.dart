import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_lock.dart';
import '../services/app_state.dart';
import '../services/system_bridge.dart';
import 'update_dialog.dart';

/// Plus > Application > Paramètres: popup player, privacy, password,
/// updates.
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
      messenger.showSnackBar(
        const SnackBar(content: Text('Mot de passe supprimé')),
      );
    } else {
      await lock.setPassword(result);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            mode == _PasswordMode.create
                ? 'Mot de passe créé'
                : 'Mot de passe modifié',
          ),
        ),
      );
    }
  }

  Future<void> _pickDelay(BuildContext context, AppLock lock) async {
    final current = lock.delayMinutes;
    final picked = await showDialog<(int?,)>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Redemander le mot de passe'),
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
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListenableBuilder(
        listenable: lock,
        builder: (context, _) => ListView(
          children: [
            const _Header('Lecture'),
            SwitchListTile(
              secondary: const Icon(Icons.picture_in_picture_alt_outlined),
              title: const Text('Lecteur popup'),
              subtitle: const Text(
                'La vidéo en cours continue dans une petite fenêtre quand '
                'vous quittez l\'application',
              ),
              value: app.popupPlayer,
              onChanged: (v) => app.popupPlayer = v,
            ),
            const Divider(),
            const _Header('Confidentialité'),
            SwitchListTile(
              secondary: const Icon(Icons.visibility_off_outlined),
              title: const Text('Masquer dans les applications récentes'),
              subtitle: const Text(
                'Aperçu noir dans le sélecteur d\'applications (bloque '
                'aussi les captures d\'écran)',
              ),
              value: app.hideInRecents,
              onChanged: (v) {
                app.hideInRecents = v;
                SystemBridge.instance.setSecure(v);
              },
            ),
            if (!lock.enabled)
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Créer un mot de passe'),
                subtitle: const Text(
                  'Demandé à l\'ouverture de l\'application',
                ),
                onTap: () => _password(context, _PasswordMode.create),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Modifier le mot de passe'),
                onTap: () => _password(context, _PasswordMode.change),
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Redemander le mot de passe'),
                subtitle: Text(AppLock.describeDelay(lock.delayMinutes)),
                onTap: () => _pickDelay(context, lock),
              ),
              ListTile(
                leading: const Icon(Icons.lock_open),
                title: const Text('Supprimer le mot de passe'),
                onTap: () => _password(context, _PasswordMode.remove),
              ),
            ],
            const Divider(),
            const _Header('Mises à jour'),
            SwitchListTile(
              secondary: const Icon(Icons.update),
              title: const Text('Rechercher au démarrage'),
              subtitle: const Text(
                'Propose les nouvelles versions publiées sur GitHub',
              ),
              value: app.autoUpdate,
              onChanged: (v) => app.autoUpdate = v,
            ),
            ListTile(
              leading: const Icon(Icons.system_update),
              title: const Text('Rechercher une mise à jour'),
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
          ? 'Mot de passe incorrect'
          : null;
      _newError = _askNew && _new.text.length < 4
          ? 'Au moins 4 caractères'
          : null;
      _confirmError = _askNew && _confirm.text != _new.text
          ? 'Les mots de passe sont différents'
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
      _PasswordMode.create => ('Créer un mot de passe', 'Créer'),
      _PasswordMode.change => ('Modifier le mot de passe', 'Modifier'),
      _PasswordMode.remove => ('Supprimer le mot de passe', 'Supprimer'),
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
                'Mot de passe actuel',
                _currentError,
                autofocus: true,
              ),
            if (_askNew) ...[
              _field(
                _new,
                'Nouveau mot de passe',
                _newError,
                autofocus: !_askCurrent,
              ),
              _field(_confirm, 'Confirmation', _confirmError),
            ],
            if (widget.mode == _PasswordMode.create)
              const Text(
                'En cas d\'oubli, il faudra effacer les données de '
                'l\'application (et la reconfigurer).',
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
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
