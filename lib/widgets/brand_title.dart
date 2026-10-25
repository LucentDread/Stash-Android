import 'package:flutter/material.dart';

/// App bar title: app logo and name, then the current page in a lighter
/// style ("[logo] Stash · Scènes"). Pages reached with a back button show
/// only [page], so the bar stays readable.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.page});

  final String? page;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    if (canPop && page != null) return Text(page!);

    final theme = Theme.of(context);
    final base = theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge;
    final muted = base?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w400,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/branding/logo.png', height: 26),
        const SizedBox(width: 10),
        Text('Stash', style: base?.copyWith(fontWeight: FontWeight.w700)),
        if (page != null) ...[
          Text('  ·  ', style: muted),
          Flexible(
            child: Text(
              page!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
          ),
        ],
      ],
    );
  }
}
