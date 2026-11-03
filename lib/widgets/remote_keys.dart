import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/system_bridge.dart';

/// Remote control (and keyboard) behaviors that no widget has by itself:
///
/// - holding OK (or Enter) on a focused item does what a long press does
///   with a finger (video preview, actions, selection…); a short press
///   still taps it. Works for any [InkWell] without changing it: this sits
///   below the app's shortcuts, so it sees the key before they turn it
///   into a tap, and only keeps it for items that have a long press;
/// - on a TV, the arrows leave a text field at its edges (a field would
///   keep them for its cursor, leaving Back as the only way out, which
///   also closes the page).
class RemoteKeys extends StatefulWidget {
  const RemoteKeys({super.key, required this.child});
  final Widget child;

  /// Keys that tap the focused item.
  static final okKeys = {
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.gameButtonA,
  };

  @override
  State<RemoteKeys> createState() => _RemoteKeysState();
}

class _RemoteKeysState extends State<RemoteKeys> {
  /// The item whose OK press is being held, and whether its long press
  /// already ran.
  InkResponse? _held;
  bool _longPressed = false;

  /// The text field having the focus, if any.
  static EditableText? _focusedField() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return null;
    if (context.widget is EditableText) return context.widget as EditableText;
    return context.findAncestorWidgetOfExactType<EditableText>();
  }

  /// The ink response the focused widget belongs to, if it has a long
  /// press.
  static InkResponse? _focusedLongPressable() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null || _focusedField() != null) return null;
    InkResponse? found;
    var depth = 0;
    context.visitAncestorElements((e) {
      final w = e.widget;
      if (w is InkResponse) {
        found = w;
        return false;
      }
      // The focus node is near its ink response; past that, it is another
      // widget's (e.g. a list around the item).
      return ++depth < 24;
    });
    final r = found;
    return r != null && r.onLongPress != null ? r : null;
  }

  /// Arrows out of the focused text field: Up/Down always for a single
  /// line (from its first/last line otherwise), Left/Right once the
  /// cursor is at the start/end of the text (e.g. Left from a search field
  /// to the tabs' rail).
  static bool _leaveField(LogicalKeyboardKey key) {
    final direction = switch (key) {
      LogicalKeyboardKey.arrowUp => TraversalDirection.up,
      LogicalKeyboardKey.arrowDown => TraversalDirection.down,
      LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
      LogicalKeyboardKey.arrowRight => TraversalDirection.right,
      _ => null,
    };
    if (direction == null) return false;
    final field = _focusedField();
    if (field == null) return false;
    final text = field.controller.text;
    final selection = field.controller.selection;
    final caret = selection.baseOffset.clamp(0, text.length);
    final atEdge = switch (direction) {
      TraversalDirection.up =>
        field.maxLines == 1 || !text.substring(0, caret).contains('\n'),
      TraversalDirection.down =>
        field.maxLines == 1 || !text.substring(caret).contains('\n'),
      // A selection is first collapsed by the arrow, as usual.
      TraversalDirection.left => selection.isCollapsed && caret == 0,
      TraversalDirection.right => selection.isCollapsed && caret == text.length,
    };
    if (!atEdge) return false;
    FocusManager.instance.primaryFocus!.focusInDirection(direction);
    return true;
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    if (SystemBridge.instance.isTv &&
        event is! KeyUpEvent &&
        _leaveField(key)) {
      return KeyEventResult.handled;
    }
    if (!RemoteKeys.okKeys.contains(key)) return KeyEventResult.ignored;
    switch (event) {
      case KeyDownEvent():
        final r = _focusedLongPressable();
        if (r == null) return KeyEventResult.ignored;
        _held = r;
        _longPressed = false;
        return KeyEventResult.handled;
      case KeyRepeatEvent():
        final r = _held;
        if (r == null) return KeyEventResult.ignored;
        if (!_longPressed) {
          _longPressed = true;
          r.onLongPress?.call();
        }
        return KeyEventResult.handled;
      case KeyUpEvent():
        final r = _held;
        if (r == null) return KeyEventResult.ignored;
        _held = null;
        if (_longPressed) {
          // Like lifting the finger (e.g. ends a scene's preview).
          r.onTapCancel?.call();
        } else {
          r.onTap?.call();
        }
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: _onKey,
    child: widget.child,
  );
}

/// Focus node for a [Slider] on a TV: Left/Right change its value, but
/// Up/Down move the focus away (a slider would keep them too).
FocusNode remoteSliderFocusNode() => FocusNode(
  onKeyEvent: (node, event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
    if (!up && event.logicalKey != LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.ignored;
    }
    node.focusInDirection(up ? TraversalDirection.up : TraversalDirection.down);
    return KeyEventResult.handled;
  },
);
