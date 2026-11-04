import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import '../services/system_bridge.dart';

/// Wrap of tappable chips for linked performers / tags / studios.
class RefChips extends StatelessWidget {
  const RefChips({
    super.key,
    required this.refs,
    required this.onTap,
    this.icon,
  });

  final List<TagRef> refs;
  final void Function(TagRef ref) onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final r in refs)
          ActionChip(
            avatar: icon == null ? null : Icon(icon, size: 16),
            label: Text(r.name),
            onPressed: () => onTap(r),
          ),
      ],
    );
  }
}

class Section extends StatelessWidget {
  const Section({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Two-column list of label / value pairs, skipping empty values.
class InfoTable extends StatelessWidget {
  const InfoTable(this.rows, {super.key});
  final List<(String, String?)> rows;

  @override
  Widget build(BuildContext context) {
    final visible = rows
        .where((r) => r.$2 != null && r.$2!.trim().isNotEmpty)
        .toList();
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (label, value) in visible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: DetailText(
                    value!,
                    style: theme.textTheme.bodyMedium,
                    readable: false,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class UrlList extends StatelessWidget {
  const UrlList(this.urls, {super.key});
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final u in urls)
          InkWell(
            onTap: () {
              final uri = Uri.tryParse(u);
              if (uri != null) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                u,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Five-star rating editor; [rating100] uses Stash's 1-100 scale.
///
/// Unrated, it reads "Not rated" (nothing at all when read-only); tapping
/// that shows the stars to pick from.
class StarRating extends StatefulWidget {
  const StarRating({super.key, required this.rating100, this.onChanged});
  final int? rating100;
  final ValueChanged<int?>? onChanged;

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  /// Stars shown although unrated, to pick a first rating.
  bool _picking = false;

  @override
  void didUpdateWidget(StarRating old) {
    super.didUpdateWidget(old);
    // Cleared: back to "Not rated".
    if (widget.rating100 == null && old.rating100 != null) _picking = false;
  }

  @override
  Widget build(BuildContext context) {
    final rating100 = widget.rating100;
    final onChanged = widget.onChanged;
    if (rating100 == null && !_picking) {
      if (onChanged == null) return const SizedBox.shrink();
      return TextButton.icon(
        onPressed: () => setState(() => _picking = true),
        icon: const Icon(Icons.star_border, color: Colors.amber),
        label: Text(tr.notRated),
      );
    }
    final stars = rating100 == null ? 0.0 : rating100 / 20;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          InkResponse(
            radius: 20,
            onTap: onChanged == null
                ? null
                // Tapping the current rating clears it, like the web UI.
                : () => onChanged(stars.round() == i ? null : i * 20),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                stars >= i
                    ? Icons.star
                    : stars >= i - 0.5
                    ? Icons.star_half
                    : Icons.star_border,
                color: Colors.amber,
                size: 28,
              ),
            ),
          ),
        if (onChanged != null)
          IconButton(
            tooltip: rating100 == null ? tr.cancel : tr.clearRating,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => rating100 == null
                ? setState(() => _picking = false)
                : onChanged(null),
          ),
      ],
    );
  }
}

/// Rating of an item, saved as soon as it changes (and restored if the
/// server refuses it).
class LiveRating extends StatefulWidget {
  const LiveRating({super.key, required this.initial, required this.save});
  final int? initial;
  final Future<void> Function(int? rating100) save;

  @override
  State<LiveRating> createState() => _LiveRatingState();
}

class _LiveRatingState extends State<LiveRating> {
  late int? _value = widget.initial;

  @override
  void didUpdateWidget(LiveRating old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial) _value = widget.initial;
  }

  Future<void> _set(int? rating) async {
    final old = _value;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _value = rating);
    try {
      await widget.save(rating);
    } catch (e) {
      if (mounted) setState(() => _value = old);
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) =>
      StarRating(rating100: _value, onChanged: _set);
}

/// A text the user may copy on a touch screen (selectable). On a TV,
/// selectable text would take the remote's focus and keep the arrows for
/// its cursor: there, a [readable] text (a description) takes the focus as
/// a block that Up/Down scroll through until its end shows, then leave;
/// other texts (short values) are plain text.
class DetailText extends StatelessWidget {
  const DetailText(this.text, {super.key, this.style, this.readable = true});
  final String text;
  final TextStyle? style;
  final bool readable;

  @override
  Widget build(BuildContext context) {
    if (!SystemBridge.instance.isTv) return SelectableText(text, style: style);
    if (!readable) return Text(text, style: style);
    return _ReadableText(text, style: style);
  }
}

class _ReadableText extends StatefulWidget {
  const _ReadableText(this.text, {this.style});
  final String text;
  final TextStyle? style;

  @override
  State<_ReadableText> createState() => _ReadableTextState();
}

class _ReadableTextState extends State<_ReadableText> {
  bool _focused = false;

  /// Room kept at the top of the page (its title bar) and at the bottom.
  static const _topRoom = 96.0;
  static const _bottomRoom = 24.0;

  /// The text's top and bottom in its scroll view, the view's height and
  /// scroll position; null outside a scroll view.
  (double, double, double, ScrollPosition)? _metrics() {
    final scrollable = Scrollable.maybeOf(context);
    final box = context.findRenderObject();
    final view = scrollable?.context.findRenderObject();
    if (scrollable == null || box is! RenderBox || view is! RenderBox) {
      return null;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: view).dy;
    return (top, top + box.size.height, view.size.height, scrollable.position);
  }

  void _scrollTo(ScrollPosition position, double offset) {
    position.animateTo(
      offset.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  /// Scrolls one step further into the text, if some of it is hidden that
  /// way. False when it all shows: the focus then moves on.
  bool _step({required bool down}) {
    final m = _metrics();
    if (m == null) return false;
    final (top, bottom, height, position) = m;
    final step = height * 0.6;
    final double delta;
    if (down) {
      final hidden = bottom - (height - _bottomRoom);
      if (hidden <= 1) return false;
      delta = hidden < step ? hidden : step;
    } else {
      final hidden = _topRoom - top;
      if (hidden <= 1) return false;
      delta = -(hidden < step ? hidden : step);
    }
    final to = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((to - position.pixels).abs() < 1) return false;
    _scrollTo(position, to);
    return true;
  }

  /// Focused from above with a text taller than the page: its start
  /// shows, not its end.
  void _showStart() {
    final m = _metrics();
    if (m == null) return;
    final (top, bottom, height, position) = m;
    if (top < _topRoom || bottom - top > height - _topRoom - _bottomRoom) {
      _scrollTo(position, position.pixels + top - _topRoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() => _focused = focused);
        // After the move's own scroll has started.
        if (focused) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _focused) _showStart();
          });
        }
      },
      onKeyEvent: (_, event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key != LogicalKeyboardKey.arrowDown &&
            key != LogicalKeyboardKey.arrowUp) {
          return KeyEventResult.ignored;
        }
        return _step(down: key == LogicalKeyboardKey.arrowDown)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _focused ? Theme.of(context).focusColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(widget.text, style: widget.style),
      ),
    );
  }
}
