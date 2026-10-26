import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/stash_repository.dart';
import '../../l10n/l10n.dart';
import '../../models/models.dart';
import '../../utils/format.dart';
import '../../widgets/detail_widgets.dart';
import '../../widgets/insets.dart';
import '../../widgets/net_image.dart';
import '../scene_filter_screen.dart';

/// One editable value of an edit form. Fields remember their initial value
/// so that only the ones the user actually changed are sent to Stash.
abstract class EditField {
  EditField(this.key, this.label);

  /// GraphQL input key.
  final String key;
  final String label;

  bool get changed;

  /// Input entries sent when the field changed.
  Map<String, dynamic> toInput();

  /// Error message, or null when the value is valid.
  String? validate() => null;

  Widget build(BuildContext context, VoidCallback onChanged);

  void dispose() {}
}

String? _blankToNull(String s) => s.trim().isEmpty ? null : s.trim();

class TextEditField extends EditField {
  TextEditField(
    super.key,
    super.label,
    String? initial, {
    this.multiline = false,
    this.required = false,
    this.hint,
    this.emptyAsNull = true,
  }) : _initial = initial ?? '',
       controller = TextEditingController(text: initial ?? '');

  final String _initial;
  final TextEditingController controller;
  final bool multiline;
  final bool required;
  final String? hint;

  /// Send null for an empty value (clears it); otherwise send "".
  final bool emptyAsNull;

  @override
  bool get changed => controller.text.trim() != _initial.trim();

  @override
  Map<String, dynamic> toInput() => {
    key: emptyAsNull ? _blankToNull(controller.text) : controller.text.trim(),
  };

  @override
  String? validate() => required && controller.text.trim().isEmpty
      ? tr.fieldRequired(label)
      : null;

  @override
  Widget build(BuildContext context, VoidCallback onChanged) => TextField(
    controller: controller,
    onChanged: (_) => onChanged(),
    minLines: multiline ? 3 : 1,
    maxLines: multiline ? 12 : 1,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: required ? '$label *' : label,
      alignLabelWithHint: multiline,
      hintText: hint,
      border: const OutlineInputBorder(),
    ),
  );

  @override
  void dispose() => controller.dispose();
}

/// Date as Stash stores it: `YYYY-MM-DD` (or `YYYY-MM` / `YYYY`).
class DateEditField extends TextEditField {
  DateEditField(super.key, super.label, super.initial)
    : super(hint: tr.dateHint);

  static final _pattern = RegExp(r'^\d{4}(-\d{2}(-\d{2})?)?$');

  @override
  String? validate() {
    final t = controller.text.trim();
    return t.isEmpty || _pattern.hasMatch(t)
        ? null
        : tr.dateFormatExpected(label, tr.dateHint);
  }

  @override
  Widget build(BuildContext context, VoidCallback onChanged) => TextField(
    controller: controller,
    onChanged: (_) => onChanged(),
    keyboardType: TextInputType.datetime,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      suffixIcon: IconButton(
        icon: const Icon(Icons.calendar_today_outlined),
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(controller.text.trim()) ?? now,
            firstDate: DateTime(1900),
            lastDate: DateTime(now.year + 5),
          );
          if (picked == null) return;
          controller.text =
              '${picked.year.toString().padLeft(4, '0')}-'
              '${picked.month.toString().padLeft(2, '0')}-'
              '${picked.day.toString().padLeft(2, '0')}';
          onChanged();
        },
      ),
    ),
  );
}

/// Whole number; [factor] converts the displayed unit to Stash's (e.g.
/// minutes shown, seconds stored).
class IntEditField extends EditField {
  IntEditField(
    super.key,
    super.label,
    int? initial, {
    this.factor = 1,
    this.suffix,
  }) : _initialText = initial == null ? '' : '${(initial / factor).round()}',
       controller = TextEditingController(
         text: initial == null ? '' : '${(initial / factor).round()}',
       );

  final String _initialText;
  final TextEditingController controller;
  final int factor;
  final String? suffix;

  @override
  bool get changed => controller.text.trim() != _initialText;

  @override
  Map<String, dynamic> toInput() {
    final v = int.tryParse(controller.text.trim());
    return {key: v == null ? null : v * factor};
  }

  @override
  String? validate() {
    final t = controller.text.trim();
    return t.isEmpty || int.tryParse(t) != null
        ? null
        : tr.integerExpected(label);
  }

  @override
  Widget build(BuildContext context, VoidCallback onChanged) => TextField(
    controller: controller,
    onChanged: (_) => onChanged(),
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      border: const OutlineInputBorder(),
    ),
  );

  @override
  void dispose() => controller.dispose();
}

class ChoiceEditField extends EditField {
  ChoiceEditField(super.key, super.label, this._initial, this.options)
    : value = _initial;

  final String? _initial;
  final Map<String?, String> options;
  String? value;

  @override
  bool get changed => value != _initial;

  @override
  Map<String, dynamic> toInput() => {key: value};

  @override
  Widget build(BuildContext context, VoidCallback onChanged) =>
      DropdownButtonFormField<String?>(
        // Rebuilt when the value is set from outside (scraping).
        key: ValueKey(value),
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final e in options.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) {
          value = v;
          onChanged();
        },
      );
}

class BoolEditField extends EditField {
  BoolEditField(super.key, super.label, this._initial) : value = _initial;

  final bool _initial;
  bool value;

  @override
  bool get changed => value != _initial;

  @override
  Map<String, dynamic> toInput() => {key: value};

  @override
  Widget build(BuildContext context, VoidCallback onChanged) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    value: value,
    onChanged: (v) {
      value = v;
      onChanged();
    },
  );
}

class RatingEditField extends EditField {
  RatingEditField(int? initial)
    : _initial = initial,
      value = initial,
      super('rating100', tr.sortRating);

  final int? _initial;
  int? value;

  @override
  bool get changed => value != _initial;

  @override
  Map<String, dynamic> toInput() => {key: value};

  @override
  Widget build(BuildContext context, VoidCallback onChanged) => Row(
    children: [
      Expanded(child: Text(label)),
      StarRating(
        rating100: value,
        onChanged: (v) {
          value = v;
          onChanged();
        },
      ),
    ],
  );
}

/// Several linked performers / tags / studios / groups.
class RefsEditField extends EditField {
  RefsEditField(
    super.key,
    super.label,
    this.kind,
    List<TagRef> initial, {
    this.encode,
  }) : _initialIds = {for (final r in initial) r.id},
       items = List.of(initial);

  final RefKind kind;
  final Set<String> _initialIds;
  final List<TagRef> items;

  /// Custom input mapping (e.g. scene groups keep their scene number).
  final Map<String, dynamic> Function(List<TagRef> items)? encode;

  @override
  bool get changed {
    final ids = {for (final r in items) r.id};
    return ids.length != _initialIds.length || !ids.containsAll(_initialIds);
  }

  @override
  Map<String, dynamic> toInput() =>
      encode?.call(items) ??
      {
        key: [for (final r in items) r.id],
      };

  @override
  Widget build(BuildContext context, VoidCallback onChanged) => _RefsEditor(
    label: label,
    items: items,
    onAdd: () async {
      final picked = await Navigator.of(context).push<List<TagRef>>(
        MaterialPageRoute(
          builder: (_) => RefPickerScreen(
            title: label,
            kind: kind,
            initial: items,
            canCreate: true,
          ),
        ),
      );
      if (picked == null) return;
      items
        ..clear()
        ..addAll(picked);
      onChanged();
    },
    onRemove: (r) {
      items.removeWhere((i) => i.id == r.id);
      onChanged();
    },
  );
}

/// A single linked studio (or parent studio).
class RefEditField extends EditField {
  RefEditField(
    super.key,
    super.label,
    this.kind,
    TagRef? initial, {
    this.required = false,
  }) : _initialId = initial?.id,
       value = initial;

  final RefKind kind;
  final String? _initialId;
  final bool required;
  TagRef? value;

  @override
  String? validate() =>
      required && value == null ? tr.fieldRequired(label) : null;

  @override
  bool get changed => value?.id != _initialId;

  @override
  Map<String, dynamic> toInput() => {key: value?.id};

  @override
  Widget build(BuildContext context, VoidCallback onChanged) => _RefsEditor(
    label: required ? '$label *' : label,
    items: [?value],
    addLabel: value == null ? tr.choose : tr.change,
    onAdd: () async {
      final picked = await Navigator.of(context).push<List<TagRef>>(
        MaterialPageRoute(
          builder: (_) => RefPickerScreen(
            title: label,
            kind: kind,
            initial: [?value],
            single: true,
            canCreate: true,
          ),
        ),
      );
      if (picked == null) return;
      value = picked.firstOrNull;
      onChanged();
    },
    onRemove: (_) {
      value = null;
      onChanged();
    },
  );
}

class _RefsEditor extends StatelessWidget {
  const _RefsEditor({
    required this.label,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    this.addLabel,
  });

  final String label;
  final List<TagRef> items;
  final VoidCallback onAdd;
  final ValueChanged<TagRef> onRemove;
  final String? addLabel;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final r in items)
            InputChip(label: Text(r.name), onDeleted: () => onRemove(r)),
          ActionChip(
            avatar: const Icon(Icons.edit_outlined, size: 18),
            label: Text(addLabel ?? (items.isEmpty ? tr.add : tr.edit)),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

/// Free list of strings (URLs, aliases).
class StringListEditField extends EditField {
  StringListEditField(super.key, super.label, List<String> initial, {this.hint})
    : _initial = List.of(initial),
      items = List.of(initial);

  final List<String> _initial;
  final List<String> items;
  final String? hint;
  final controller = TextEditingController();

  @override
  bool get changed {
    // Text typed but not yet added counts as a change.
    if (controller.text.trim().isNotEmpty) return true;
    if (items.length != _initial.length) return true;
    for (var i = 0; i < items.length; i++) {
      if (items[i] != _initial[i]) return true;
    }
    return false;
  }

  List<String> get _all => [
    ...items,
    if (controller.text.trim().isNotEmpty) controller.text.trim(),
  ];

  @override
  Map<String, dynamic> toInput() => {key: _all};

  @override
  Widget build(BuildContext context, VoidCallback onChanged) {
    void add() {
      final t = controller.text.trim();
      if (t.isEmpty) return;
      items.add(t);
      controller.clear();
      onChanged();
    }

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            Row(
              children: [
                Expanded(child: Text(items[i])),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    items.removeAt(i);
                    onChanged();
                  },
                ),
              ],
            ),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => add(),
            decoration: InputDecoration(
              hintText: hint ?? tr.addHint,
              isDense: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: add,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() => controller.dispose();
}

/// Position in a video, typed as `m:ss` or `h:mm:ss` (or plain seconds).
class TimeEditField extends EditField {
  TimeEditField(
    super.key,
    super.label,
    double? initial, {
    this.required = false,
  }) : _initialText = initial == null ? '' : formatDuration(initial),
       controller = TextEditingController(
         text: initial == null ? '' : formatDuration(initial),
       );

  final String _initialText;
  final TextEditingController controller;
  final bool required;

  /// Seconds, or null when empty or invalid.
  static double? parse(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final parts = t.split(':');
    if (parts.length > 3) return null;
    var seconds = 0.0;
    for (final p in parts) {
      final v = double.tryParse(p);
      if (v == null || v < 0) return null;
      seconds = seconds * 60 + v;
    }
    return seconds;
  }

  @override
  bool get changed => controller.text.trim() != _initialText;

  @override
  Map<String, dynamic> toInput() => {key: parse(controller.text)};

  @override
  String? validate() {
    final t = controller.text.trim();
    if (t.isEmpty) return required ? tr.fieldRequired(label) : null;
    return parse(t) == null ? tr.timeFormatExpected(label) : null;
  }

  @override
  Widget build(BuildContext context, VoidCallback onChanged) => TextField(
    controller: controller,
    onChanged: (_) => onChanged(),
    keyboardType: TextInputType.datetime,
    decoration: InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: 'm:ss',
      border: const OutlineInputBorder(),
    ),
  );

  @override
  void dispose() => controller.dispose();
}

/// Image chosen from the phone or given by URL. Stash accepts both a URL
/// and a base64 data URI for image inputs.
class ImageEditField extends EditField {
  ImageEditField(super.key, super.label, this.currentUrl);

  final String? currentUrl;

  /// New image (data URI or URL), null while unchanged.
  String? value;
  Uint8List? _pickedBytes;

  @override
  bool get changed => value != null;

  @override
  Map<String, dynamic> toInput() => {key: value};

  /// Uses [image] (data URI or URL), e.g. a scraped cover.
  void setImage(String image) {
    _pickedBytes = image.startsWith('data:')
        ? UriData.parse(image).contentAsBytes()
        : null;
    value = image;
  }

  Future<void> _pick(VoidCallback onChanged) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Keeps uploads reasonable: Stash stores the image as sent.
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 90,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final mime =
        file.mimeType ??
        (file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
    _pickedBytes = bytes;
    value = 'data:$mime;base64,${base64Encode(bytes)}';
    onChanged();
  }

  Future<void> _fromUrl(BuildContext context, VoidCallback onChanged) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(tr.use),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url == null || url.isEmpty) return;
    _pickedBytes = null;
    value = url;
    onChanged();
  }

  @override
  Widget build(BuildContext context, VoidCallback onChanged) {
    final Widget preview;
    if (_pickedBytes != null) {
      preview = Image.memory(_pickedBytes!, fit: BoxFit.contain);
    } else if (value != null) {
      preview = Image.network(value!, fit: BoxFit.contain);
    } else {
      preview = NetImage(currentUrl, fit: BoxFit.contain);
    }
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          SizedBox(width: 96, height: 96, child: preview),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => _pick(onChanged),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(tr.fromPhone),
                ),
                TextButton.icon(
                  onPressed: () => _fromUrl(context, onChanged),
                  icon: const Icon(Icons.link),
                  label: Text(tr.fromUrl),
                ),
                if (value != null)
                  TextButton.icon(
                    onPressed: () {
                      value = null;
                      _pickedBytes = null;
                      onChanged();
                    },
                    icon: const Icon(Icons.undo),
                    label: Text(tr.cancel),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic edit screen: shows [fields], sends the changed ones to [save].
class EditScreen extends StatefulWidget {
  const EditScreen({
    super.key,
    required this.title,
    required this.fields,
    required this.save,
    this.create = false,
    this.delete,
    this.deleteLabel,
    this.extraActions,
  });

  final String title;
  final List<EditField> fields;
  final Future<void> Function(Map<String, dynamic> input) save;

  /// More app bar buttons; `refresh` redraws the form after they change
  /// field values (e.g. scraping).
  final List<Widget> Function(BuildContext context, VoidCallback refresh)?
  extraActions;

  /// Creation form: every field is sent and saving needs no change.
  final bool create;

  /// Shows a delete action (with confirmation) when set.
  final Future<void> Function()? delete;
  final String? deleteLabel;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  bool _saving = false;

  bool get _changed => widget.fields.any((f) => f.changed);

  @override
  void dispose() {
    for (final f in widget.fields) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final error = widget.fields
        .map((f) => f.validate())
        .whereType<String>()
        .firstOrNull;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final input = <String, dynamic>{
      for (final f in widget.fields)
        if (widget.create || f.changed) ...f.toInput(),
    };
    setState(() => _saving = true);
    try {
      await widget.save(input);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(tr.saved)));
      Navigator.of(context).pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.questionOf(widget.deleteLabel ?? tr.delete)),
        content: Text(tr.cannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await widget.delete!();
      messenger.showSnackBar(SnackBar(content: Text(tr.deleted)));
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.discardChangesQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.continueEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.discard),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final changed = _changed;
    return PopScope(
      canPop: !changed || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            ...?widget.extraActions?.call(context, () => setState(() {})),
            if (widget.delete != null)
              IconButton(
                tooltip: widget.deleteLabel ?? tr.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: _saving ? null : _delete,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: (changed || widget.create) && !_saving
                    ? _save
                    : null,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(tr.save),
              ),
            ),
          ],
        ),
        body: ListView.separated(
          padding: withNavBar(
            context,
            const EdgeInsets.fromLTRB(16, 16, 16, 32),
          ),
          itemCount: widget.fields.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) =>
              widget.fields[i].build(context, () => setState(() {})),
        ),
      ),
    );
  }
}
