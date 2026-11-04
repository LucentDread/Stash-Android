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
/// room around it (a row's title above its items), and the first item
/// that can take the focus brings the page back to its very top (what
/// sits above it, e.g. statistics, cannot take the focus to show).
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
  final nodeRect = node.rect;
  final firstInPage = !node.nearestScope!.traversalDescendants.any(
    (n) =>
        n != node &&
        n.context != null &&
        n.rect.bottom <= nodeRect.top + 1 &&
        _scrollableOf(n.context!, Axis.vertical) == page,
  );
  if (firstInPage) target = position.minScrollExtent;
  target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
  if ((target - position.pixels).abs() >= 1) {
    position.animateTo(target, duration: d, curve: c);
  }
}

/// How the remote moves the focus on a TV: Flutter's directional moves,
/// scrolling smoothly.
///
/// With [rowsFirst], Up/Down go to the nearest row above/below, then to
/// its item closest horizontally. Flutter's own choice only looks at items
/// overlapping the focused one horizontally: from a button on the right,
/// Down skipped every row starting further left (e.g. to a scene's last
/// tag).
class TvTraversalPolicy extends ReadingOrderTraversalPolicy {
  TvTraversalPolicy({this.rowsFirst = false})
    : super(requestFocusCallback: smoothRequestFocus);

  final bool rowsFirst;

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final along =
        direction == TraversalDirection.left ||
        direction == TraversalDirection.right;
    if (along && currentNode.context != null) {
      final moved = _alongRow(currentNode, direction);
      if (moved != null) return moved;
    }
    final down = direction == TraversalDirection.down;
    if (!rowsFirst || !(down || direction == TraversalDirection.up)) {
      return super.inDirection(currentNode, direction);
    }
    final scope = currentNode.nearestScope;
    if (scope == null || currentNode.context == null) return false;
    final from = currentNode.rect;
    // Items of the next row may start a few pixels above the focused
    // one's bottom (or below its top) when they are taller.
    const slack = 4.0;
    final candidates = [
      for (final n in scope.traversalDescendants)
        if (n != currentNode &&
            n.context != null &&
            !n.rect.isEmpty &&
            (down
                ? n.rect.top >= from.bottom - slack
                : n.rect.bottom <= from.top + slack))
          n,
    ];
    if (candidates.isEmpty) return false;
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
    requestFocusCallback(
      target,
      alignmentPolicy: down
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
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
    final from = currentNode.rect;
    const slack = 4.0;
    final next = [
      for (final n in scope.traversalDescendants)
        if (n != currentNode &&
            n.context != null &&
            !n.rect.isEmpty &&
            (right
                ? n.rect.left >= from.right - slack
                : n.rect.right <= from.left + slack) &&
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
}
