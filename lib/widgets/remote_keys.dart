import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../services/system_bridge.dart';

/// Remote control (and keyboard) behaviors that no widget has by itself:
///
/// - holding OK (or Enter) on a focused item does what a long press does
///   with a finger (video preview, actions, selection…); a short press
///   still taps it. Works for any [InkWell] without changing it: this sits
///   below the app's shortcuts, so it sees the key before they turn it
///   into a tap, and only keeps it for items that have a long press;
/// - on a TV, Up/Down leave a text field (a single-line field would keep
///   them for its cursor, leaving Back as the only way out, which also
///   closes the page).
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

  /// Up/Down out of the focused text field: always for a single line,
  /// from its first/last line otherwise.
  static bool _leaveField(LogicalKeyboardKey key) {
    final up = key == LogicalKeyboardKey.arrowUp;
    if (!up && key != LogicalKeyboardKey.arrowDown) return false;
    final field = _focusedField();
    if (field == null) return false;
    if (field.maxLines != 1) {
      final text = field.controller.text;
      final caret = field.controller.selection.baseOffset.clamp(0, text.length);
      final otherLines = up
          ? text.substring(0, caret).contains('\n')
          : text.substring(caret).contains('\n');
      if (otherLines) return false;
    }
    final node = FocusManager.instance.primaryFocus!;
    node.focusInDirection(up ? TraversalDirection.up : TraversalDirection.down);
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

/// On a TV, a thick frame around whatever has the remote's focus, on top
/// of every page: the ink's own focus color is faint, and hidden under
/// pictures. It follows the item while pages scroll or slide in.
class FocusRing extends StatefulWidget {
  const FocusRing({super.key, required this.child});
  final Widget child;

  /// A focused area this big is a page catching keys (player, viewer),
  /// not an item: no frame.
  static const _maxShare = 0.6;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _stack = GlobalKey();
  late final Ticker _ticker = createTicker(_tick);
  Rect? _rect;
  int _stableFrames = 0;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_wake);
    FocusManager.instance.addHighlightModeListener(_onMode);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_wake);
    FocusManager.instance.removeHighlightModeListener(_onMode);
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() => _wake();

  void _onMode(FocusHighlightMode _) => _wake();

  /// Follows the focus for a while: until the frame has stayed put for
  /// half a second (the end of a scroll or page transition).
  void _wake() {
    _stableFrames = 0;
    if (!_ticker.isActive && mounted) _ticker.start();
  }

  void _tick(Duration _) {
    final rect = _focusRect();
    if (rect != _rect) {
      setState(() => _rect = rect);
      _stableFrames = 0;
    } else if (++_stableFrames > 30) {
      _ticker.stop();
    }
  }

  Rect? _focusRect() {
    if (FocusManager.instance.highlightMode != FocusHighlightMode.traditional) {
      return null;
    }
    final node = FocusManager.instance.primaryFocus;
    final box = _stack.currentContext?.findRenderObject() as RenderBox?;
    if (node == null || node is FocusScopeNode || box == null) return null;
    final context = node.context;
    if (context == null || !context.mounted) return null;
    final target = context.findRenderObject();
    if (target is! RenderBox || !target.attached || !target.hasSize) {
      return null;
    }
    final topLeft = box.globalToLocal(target.localToGlobal(Offset.zero));
    final rect = topLeft & target.size;
    final screen = box.size;
    if (rect.width * rect.height >
        FocusRing._maxShare * screen.width * screen.height) {
      return null;
    }
    return rect;
  }

  @override
  Widget build(BuildContext context) {
    final rect = _rect;
    final scheme = Theme.of(context).colorScheme;
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _wake();
        return false;
      },
      child: Stack(
        key: _stack,
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (rect != null)
            Positioned.fromRect(
              rect: rect.inflate(4),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.onSurface, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.8),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
