import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Long presses with a remote control or a keyboard: holding OK (or
/// Enter) on a focused item does what a long press does with a finger
/// (video preview, actions, selection…); a short press still taps it.
///
/// Works for any [InkWell] (cards, list tiles, buttons…) without changing
/// them: it sits below the app's shortcuts, so it sees the key before they
/// turn it into a tap, and only keeps it for items that have a long press.
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

  /// The ink response the focused widget belongs to, if it has a long
  /// press. Text fields keep Enter.
  static InkResponse? _focusedLongPressable() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null || context.widget is EditableText) return null;
    InkResponse? found;
    var depth = 0;
    context.visitAncestorElements((e) {
      final w = e.widget;
      if (w is EditableText) return false;
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

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (!RemoteKeys.okKeys.contains(event.logicalKey)) {
      return KeyEventResult.ignored;
    }
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

/// A [Card] that is clearly framed while it, or something in it, has the
/// focus of a remote control or keyboard: its picture would otherwise hide
/// the ink's faint focus color. Nothing changes with touch.
class FocusCard extends StatefulWidget {
  const FocusCard({
    super.key,
    this.clipBehavior,
    this.margin,
    this.shape,
    required this.child,
  });

  final Clip? clipBehavior;
  final EdgeInsetsGeometry? margin;
  final ShapeBorder? shape;
  final Widget child;

  @override
  State<FocusCard> createState() => _FocusCardState();
}

class _FocusCardState extends State<FocusCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final framed =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) => setState(() => _focused = f),
      child: Card(
        clipBehavior: widget.clipBehavior,
        margin: widget.margin,
        shape: framed
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                // Not the primary color, which marks selected items.
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 3,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              )
            : widget.shape,
        child: widget.child,
      ),
    );
  }
}
