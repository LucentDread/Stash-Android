import 'package:flutter/material.dart';

/// The app's launch animation, over the app while it starts: the logo in
/// the middle of the screen slides to the left as it grows, the name comes
/// out from behind it, and the logo and name end up centered together;
/// then it fades into the app.
///
/// It starts where Android's launch screen leaves off (see
/// res/drawable/launch_background.xml): the same background, and the logo
/// at the same size and place, so that the switch does not show. From
/// Android 12 the system draws its launch screen without the logo
/// (res/values-v31/styles.xml): with [logoShown] false, it appears first.
///
/// Played once, at a cold start (it is built by main()); skipped when the
/// device asks for no animations.
class LaunchIntro extends StatefulWidget {
  const LaunchIntro({super.key, required this.logoShown, required this.child});

  /// Whether Android's launch screen showed the logo (before Android 12).
  final bool logoShown;
  final Widget child;

  /// Background of the launch screen and of the app (colors.xml).
  static const background = Color(0xFF101418);

  /// The logo on Android's launch screen: 44.2 × 37.7 dp, its center a
  /// little right of and below the screen's (it is drawn within the
  /// 108 dp canvas of the launcher icon's foreground).
  static const logoSize = Size(44.19, 37.65);
  static const logoOffset = Offset(1.95, 3.11);

  static const duration = Duration(milliseconds: 1600);

  @override
  State<LaunchIntro> createState() => _LaunchIntroState();
}

class _LaunchIntroState extends State<LaunchIntro>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: LaunchIntro.duration,
  );
  bool _done = false;

  // Phases, as parts of the whole.
  late final _appear = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.12, curve: Curves.easeOut),
  );
  late final _move = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.1, 0.48, curve: Curves.easeInOutCubic),
  );
  late final _slide = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.28, 0.66, curve: Curves.easeOutCubic),
  );
  late final _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.82, 1, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _done = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_done || _controller.isAnimating) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _done = true;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (!_done)
            // Touches and keys go to the app meanwhile.
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Opacity(
                  opacity: 1 - _fade.value,
                  child: _frame(MediaQuery.sizeOf(context)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const _name = 'Stash';
  static const _nameStyle = TextStyle(
    color: Color(0xFFE8D5C4),
    fontSize: 56,
    fontWeight: FontWeight.bold,
    fontFamily: 'Roboto',
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  /// Height of the logo at the end, and the space before the name.
  static const _endHeight = 72.0;
  static const _gap = 20.0;

  Widget _frame(Size screen) {
    final center = screen.center(Offset.zero);
    final name = TextPainter(
      text: const TextSpan(text: _name, style: _nameStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final endScale = _endHeight / LaunchIntro.logoSize.height;
    final endLogoWidth = LaunchIntro.logoSize.width * endScale;
    final total = endLogoWidth + _gap + name.width;
    final left = center.dx - total / 2;
    final start = center + LaunchIntro.logoOffset;
    final end = Offset(left + endLogoWidth / 2, center.dy);

    final logoCenter = Offset.lerp(start, end, _move.value)!;
    final scale = 1 + (endScale - 1) * _move.value;
    final logo = LaunchIntro.logoSize * scale;
    // The name starts behind the logo and slides out to its right.
    final nameLeft =
        logoCenter.dx -
        name.width / 2 +
        ((left + endLogoWidth + _gap) - (logoCenter.dx - name.width / 2)) *
            _slide.value;

    return ColoredBox(
      color: LaunchIntro.background,
      child: Stack(
        children: [
          // Only right of the logo's middle: it comes from behind it.
          Positioned.fill(
            child: ClipRect(
              clipper: _RightOf(logoCenter.dx),
              child: Stack(
                children: [
                  Positioned(
                    left: nameLeft,
                    top: center.dy - name.height / 2,
                    child: Opacity(
                      opacity: _slide.value.clamp(0.0, 1.0),
                      child: const Text(_name, style: _nameStyle),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: logoCenter.dx - logo.width / 2,
            top: logoCenter.dy - logo.height / 2,
            width: logo.width,
            height: logo.height,
            child: Opacity(
              opacity: widget.logoShown ? 1 : _appear.value,
              child: Image.asset(
                'assets/branding/logo.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps what lies right of [x].
class _RightOf extends CustomClipper<Rect> {
  _RightOf(this.x);
  final double x;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(x.clamp(0, size.width), 0, size.width, size.height);

  @override
  bool shouldReclip(_RightOf old) => old.x != x;
}
