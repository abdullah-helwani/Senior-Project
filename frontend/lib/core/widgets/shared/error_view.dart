import 'package:first_try/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

/// Friendly error display with optional retry. Soft error-tint halo +
/// truncated message body so a verbose `DioException` doesn't take over the
/// screen. Pass `compact: true` for inline use inside cards.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool compact;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final iconWidget = Container(
      width: compact ? 56 : 88,
      height: compact ? 56 : 88,
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: compact ? Radii.lgRadius : Radii.xlRadius,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: compact ? 28 : 36,
        color: cs.onErrorContainer,
      ),
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            SizedBox(height: compact ? 12 : 18),
            Text(
              compact ? 'Something went wrong' : 'Something broke',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                _trim(message),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: compact ? 12 : 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Strip Dio's noisy prefix and clip really long messages.
  String _trim(String raw) {
    var msg = raw;
    msg = msg.replaceFirst(RegExp(r'^Exception: '), '');
    msg = msg.replaceFirst(RegExp(r'^DioException \[[^\]]+\]: '), '');
    if (msg.length > 240) msg = '${msg.substring(0, 240)}…';
    return msg;
  }
}
