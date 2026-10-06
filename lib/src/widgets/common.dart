import 'package:flutter/material.dart';

import '../nexwall_api.dart';

/// Shows "N left today" from the last API response.
class QuotaChip extends StatelessWidget {
  const QuotaChip({super.key, required this.api});

  final NexWallApi api;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: api.remainingToday,
      builder: (context, remaining, _) {
        if (remaining == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Tooltip(
              message: 'API requests remaining today',
              child: Text(
                '$remaining left today',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Centered error message with a retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is NexWallException
        ? (error as NexWallException).friendlyMessage
        : '$error';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
