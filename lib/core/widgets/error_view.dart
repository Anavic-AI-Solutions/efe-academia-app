import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final String? detail;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.detail,
    this.retryLabel = 'Retry',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(retryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
