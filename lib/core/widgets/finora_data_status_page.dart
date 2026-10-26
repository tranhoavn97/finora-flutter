import 'package:flutter/material.dart';

import 'glass_widgets.dart';

/// Shared state for financial pages before their figures are trustworthy.
class FinoraDataStatusPage extends StatelessWidget {
  final String title;
  final bool loading;
  final VoidCallback onRetry;
  final VoidCallback? onBack;

  const FinoraDataStatusPage({
    super.key,
    required this.title,
    required this.loading,
    required this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) => GlassScaffold(
        appBar: GlassTopBar(title: title, onBack: onBack),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    loading
                        ? Icons.cloud_sync_outlined
                        : Icons.cloud_off_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                    loading
                        ? 'Đang tải dữ liệu tài chính…'
                        : 'Chưa tải được dữ liệu tài chính.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium),
                if (!loading) ...[
                  const SizedBox(height: 8),
                  const Text(
                      'Số liệu sẽ hiển thị sau khi kết nối được khôi phục.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                      onPressed: onRetry, child: const Text('Thử lại')),
                ],
              ],
            ),
          ),
        ),
      );
}
