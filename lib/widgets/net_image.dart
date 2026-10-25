import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

/// Network image from the Stash server (adds the API key, caches on disk).
class NetImage extends StatelessWidget {
  const NetImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.image_outlined,
    this.alignment = Alignment.center,
    this.showPlaceholder = true,
  });

  final String? url;
  final BoxFit fit;
  final IconData placeholderIcon;
  final Alignment alignment;

  /// When false, nothing is drawn while loading or on error.
  final bool showPlaceholder;

  @override
  Widget build(BuildContext context) {
    final client = context.read<AppState>().client;
    final resolved = client?.mediaUrl(url);
    if (!showPlaceholder && resolved == null) return const SizedBox.shrink();
    final Widget placeholder = !showPlaceholder
        ? const SizedBox.shrink()
        : ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Icon(
                placeholderIcon,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
    if (resolved == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: resolved,
      httpHeaders: client!.authHeaders,
      fit: fit,
      alignment: alignment,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}
