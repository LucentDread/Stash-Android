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
