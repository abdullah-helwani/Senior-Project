import 'package:flutter/material.dart';

/// Simple centered indeterminate loader. Used as a default fallback when a
/// screen doesn't have skeleton placeholders. For lists / detail views,
/// prefer the `Skeleton` widgets in `core/widgets/ui/skeleton.dart` —
/// they communicate the shape of incoming content much better than a spinner.
class LoadingView extends StatelessWidget {
  /// Optional helper text rendered under the spinner.
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: cs.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
