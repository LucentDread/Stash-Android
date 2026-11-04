import 'package:flutter/material.dart';

/// How the remote's focus shows on a TV, drawn by each item in its own
/// shape (a frame laid over the page would not match the items' corners
/// and would also frame text fields, which have their own focused border):
///
/// - buttons of every kind (filled, outlined, text, icon) and chips: a
///   white outline along their shape;
/// - list rows, tabs, the navigation rail: a clear light background;
/// - pictures (cards, image tiles): [FocusFrame], since a background would
///   be hidden under the picture.
ThemeData tvTheme(ThemeData base) {
  const ring = BorderSide(color: Colors.white, width: 3);
  final outline = WidgetStateProperty.resolveWith<BorderSide?>(
    (s) => s.contains(WidgetState.focused) ? ring : null,
  );
  final fill = Colors.white.withValues(alpha: 0.2);
  final buttons = ButtonStyle(side: outline);
  return base.copyWith(
    focusColor: fill,
    filledButtonTheme: FilledButtonThemeData(style: buttons),
    outlinedButtonTheme: OutlinedButtonThemeData(style: buttons),
    textButtonTheme: TextButtonThemeData(style: buttons),
    elevatedButtonTheme: ElevatedButtonThemeData(style: buttons),
    iconButtonTheme: IconButtonThemeData(style: buttons),
    segmentedButtonTheme: SegmentedButtonThemeData(style: buttons),
    chipTheme: base.chipTheme.copyWith(
      side: WidgetStateBorderSide.resolveWith(
        (s) => s.contains(WidgetState.focused) ? ring : null,
      ),
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      overlayColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.focused) ? fill : null,
      ),
    ),
  );
}

/// A white outline over [child] while something in it has the focus of a
/// remote control or keyboard, following its rounded corners ([radius]):
/// for pictures, which would hide an ink highlight. Nothing changes with
/// touch.
class FocusFrame extends StatefulWidget {
  const FocusFrame({super.key, this.radius = 12, required this.child});

  final double radius;
  final Widget child;

  @override
  State<FocusFrame> createState() => _FocusFrameState();
}

class _FocusFrameState extends State<FocusFrame> {
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
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: framed
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(color: Colors.white, width: 3),
              )
            : const BoxDecoration(),
        child: widget.child,
      ),
    );
  }
}

/// The nearest scroll view around [context] scrolling along [axis].
ScrollableState? _scrollableOf(BuildContext context, Axis axis) {
  var s = Scrollable.maybeOf(context);
  while (s != null && s.position.axis != axis) {
    s = Scrollable.maybeOf(s.context);
  }
  return s;
}

/// Room kept above a focused item (its row's title) and below it.
const _roomAbove = 72.0;
const _roomBelow = 32.0;

/// Moves the focus to [node] and scrolls it into view smoothly, instead
/// of the jump Flutter makes by default. Vertically, it also keeps some
/// room around it (a row's title above its items).
void smoothRequestFocus(
  FocusNode node, {
  ScrollPositionAlignmentPolicy? alignmentPolicy,
  double? alignment,
  Duration? duration,
  Curve? curve,
}) {
  node.requestFocus();
  final context = node.context;
  if (context == null) return;
  final d = duration == null || duration == Duration.zero
      ? const Duration(milliseconds: 220)
      : duration;
  final c = curve ?? Curves.easeOutCubic;
  // Along every scroll view (e.g. a row of the home page inside it).
  Scrollable.ensureVisible(
    context,
    alignment: alignment ?? 1,
    alignmentPolicy: alignmentPolicy ?? ScrollPositionAlignmentPolicy.explicit,
    duration: d,
    curve: c,
  );
  // Then the page itself, with room around the item (replaces its move).
  final page = _scrollableOf(context, Axis.vertical);
  final view = page?.context.findRenderObject();
  final box = context.findRenderObject();
  if (page == null || view is! RenderBox || box is! RenderBox) return;
  if (!box.attached || !view.attached) return;
  final position = page.position;
  final top = box.localToGlobal(Offset.zero, ancestor: view).dy;
  final bottom = top + box.size.height;
  final height = view.size.height;
  var target = position.pixels;
  if (top - _roomAbove < 0) {
    target += top - _roomAbove;
  } else if (bottom + _roomBelow > height) {
    target += bottom + _roomBelow - height;
  }
  target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
  if ((target - position.pixels).abs() >= 1) {
    position.animateTo(target, duration: d, curve: c);
  }
}

/// Marks a part of the screen the remote's Up/Down stay within (e.g. the
/// tabs' rail beside a page): put it on a [Focus] around that part.
class TvRegionNode extends FocusNode {
  TvRegionNode() : super(canRequestFocus: false, skipTraversal: true);
}

/// Where [node] is on screen; null when it has no place there (e.g. the
/// focused item, scrolled far out of a list, is kept but not laid out).
Rect? _rectOf(FocusNode node) {
  if (node.context == null) return null;
  final r = node.rect;
  return r.isFinite && !r.isEmpty ? r : null;
}

TvRegionNode? _regionOf(FocusNode node) {
  for (final a in node.ancestors) {
    if (a is TvRegionNode) return a;
  }
  return null;
}

/// How the remote moves the focus on a TV, the same way on every page:
///
/// - Up/Down go to the nearest row above/below (its items closest to the
///   focused one vertically, whatever their width), then to its item
///   closest horizontally. Flutter's own choice only looks at items lined
///   up with the focused one, so it skipped a short row for one further
///   away (e.g. from the right end of a home row, past a shorter row).
///   They stay within the focused item's [TvRegionNode], if any (the
///   rail).
/// - When nothing can take the focus that way, or the next item is more
///   than half a screen away, Up/Down scroll the page a step instead:
///   whatever cannot take the focus (information, statistics) can still
///   be read.
/// - Left/Right move along a horizontal row and stop at its right end;
///   elsewhere, Flutter's move, if anything lies that way at all.
/// - Pages scroll smoothly to the focus ([smoothRequestFocus]).
class TvTraversalPolicy extends ReadingOrderTraversalPolicy {
  TvTraversalPolicy() : super(requestFocusCallback: smoothRequestFocus);

  static const _slack = 4.0;

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    // No "back to where the focus came from" memory: mixed with the moves
    // made here, it sent the focus to unexpected items.
    final scope = currentNode.nearestScope;
    if (scope != null) invalidateScopeData(scope);
    // Nothing focused yet (a page just opened): Flutter's first item.
    if (scope == null ||
        currentNode is FocusScopeNode ||
        scope.focusedChild == null ||
        currentNode.context == null) {
      return super.inDirection(currentNode, direction);
    }
    switch (direction) {
      case TraversalDirection.up:
      case TraversalDirection.down:
        return _vertical(
          currentNode,
          scope,
          down: direction == TraversalDirection.down,
        );
      case TraversalDirection.left:
      case TraversalDirection.right:
        final moved = _alongRow(currentNode, direction);
        if (moved != null) return moved;
        // Nothing that way (e.g. Left from the rail, at the screen's edge):
        // stay, instead of Flutter's fallback to some other item.
        if (!_anythingToward(currentNode, direction)) return true;
        return super.inDirection(currentNode, direction);
    }
  }

  bool _vertical(
    FocusNode currentNode,
    FocusScopeNode scope, {
    required bool down,
  }) {
    final region = _regionOf(currentNode);
    final page = region == null
        ? _scrollableOf(currentNode.context!, Axis.vertical)
        : null;
    final view = _viewRect(page);
    // The focused item scrolled out of sight (see [_rectOf]): from the
    // edge of the page it left by, so the next move picks what shows.
    final from =
        _rectOf(currentNode) ??
        (view == null
            ? null
            : down
            ? Rect.fromLTWH(view.left, view.top - 1, view.width, 1)
            : Rect.fromLTWH(view.left, view.bottom, view.width, 1));
    if (from == null) return true;
    final candidates = [
      for (final n in scope.traversalDescendants)
        if (n != currentNode && _regionOf(n) == region)
          if (_rectOf(n) case final r?)
            if (down
                ? r.top >= from.bottom - _slack
                : r.bottom <= from.top + _slack)
              n,
    ];
    if (candidates.isEmpty) {
      _scrollStep(page, down: down);
      return true;
    }
    double gap(FocusNode n) =>
        down ? n.rect.top - from.bottom : from.top - n.rect.bottom;
    final nearest = candidates.map(gap).reduce((a, b) => a < b ? a : b);
    // The row: items about as close as the nearest one.
    final row = candidates.where((n) => gap(n) <= nearest + 12);
    final target = row.reduce(
      (a, b) =>
          (a.rect.center.dx - from.center.dx).abs() <=
              (b.rect.center.dx - from.center.dx).abs()
          ? a
          : b,
    );
    // Over half a screen of the page before it: show that first.
    if (view != null) {
      final hidden = down
          ? target.rect.top - view.bottom
          : view.top - target.rect.bottom;
      if (hidden > view.height / 2 && _scrollStep(page, down: down)) {
        return true;
      }
    }
    requestFocusCallback(
      target,
      alignmentPolicy: down
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
    return true;
  }

  /// The visible part of [page], on screen.
  static Rect? _viewRect(ScrollableState? page) {
    final box = page?.context.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Scrolls [page] by most of a screen; false when it cannot go further.
  static bool _scrollStep(ScrollableState? page, {required bool down}) {
    if (page == null) return false;
    final p = page.position;
    final to = (p.pixels + (down ? 0.6 : -0.6) * p.viewportDimension).clamp(
      p.minScrollExtent,
      p.maxScrollExtent,
    );
    if ((to - p.pixels).abs() < 1) return false;
    p.animateTo(
      to,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    return true;
  }

  /// Left/Right in a horizontal row (e.g. on the home page): to the next
  /// item of the same row. At its right end, nothing (Flutter went to the
  /// row below); at its left end, the usual move (e.g. to the tabs' rail).
  /// Null outside a horizontal row.
  bool? _alongRow(FocusNode currentNode, TraversalDirection direction) {
    final row = _scrollableOf(currentNode.context!, Axis.horizontal);
    final scope = currentNode.nearestScope;
    if (row == null || scope == null) return null;
    final right = direction == TraversalDirection.right;
    final from = _rectOf(currentNode);
    if (from == null) return null;
    final next = [
      for (final n in scope.traversalDescendants)
        if (n != currentNode)
          if (_rectOf(n) case final r?)
            if ((right
                    ? r.left >= from.right - _slack
                    : r.right <= from.left + _slack) &&
                _scrollableOf(n.context!, Axis.horizontal) == row)
              n,
    ];
    if (next.isEmpty) return right ? true : null;
    double gap(FocusNode n) =>
        right ? n.rect.left - from.right : from.left - n.rect.right;
    final target = next.reduce((a, b) => gap(a) <= gap(b) ? a : b);
    requestFocusCallback(
      target,
      alignmentPolicy: right
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
    return true;
  }

  /// Whether an item lies entirely [direction] of [currentNode].
  static bool _anythingToward(
    FocusNode currentNode,
    TraversalDirection direction,
  ) {
    final scope = currentNode.nearestScope;
    if (scope == null || currentNode.context == null) return true;
    final from = _rectOf(currentNode);
    if (from == null) return true;
    return scope.traversalDescendants.any((n) {
      if (n == currentNode) return false;
      final r = _rectOf(n);
      if (r == null) return false;
      return switch (direction) {
        TraversalDirection.left => r.right <= from.left + _slack,
        TraversalDirection.right => r.left >= from.right - _slack,
        TraversalDirection.up => r.bottom <= from.top + _slack,
        TraversalDirection.down => r.top >= from.bottom - _slack,
      };
    });
  }
}
