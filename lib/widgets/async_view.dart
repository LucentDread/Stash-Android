import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'data_refresh.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(error.toString(), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onRetry, child: Text(tr.retry)),
            ],
          ],
        ),
      ),
    );
  }
}

/// FutureBuilder with standard loading / error states and a retry button.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, VoidCallback reload)
  builder;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> with DataRefresh {
  late Future<T> _future = widget.load();

  void _reload() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    watchServerData(_reload);
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return ErrorView(error: snap.error!, onRetry: _reload);
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return widget.builder(context, snap.data as T, _reload);
      },
    );
  }
}
