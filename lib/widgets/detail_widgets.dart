import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';

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
                  child: SelectableText(
                    value!,
                    style: theme.textTheme.bodyMedium,
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
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating100, this.onChanged});
  final int? rating100;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final stars = rating100 == null ? 0.0 : rating100! / 20;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          InkResponse(
            radius: 20,
            onTap: onChanged == null
                ? null
                // Tapping the current rating clears it, like the web UI.
                : () => onChanged!(stars.round() == i ? null : i * 20),
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
        // Keeps its room when unrated so the stars do not move.
        if (onChanged != null)
          Visibility.maintain(
            visible: rating100 != null,
            child: IconButton(
              tooltip: tr.clearRating,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => onChanged!(null),
            ),
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
