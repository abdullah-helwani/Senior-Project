import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:flutter/material.dart';

/// One place to express the "loading / empty / error / loaded" branch so every
/// screen gets the same look & retry behavior.
///
/// Prefer using this at the child of a `BlocBuilder`, not replacing it:
///
/// ```dart
/// BlocBuilder<HomeworkCubit, HomeworkState>(
///   builder: (_, state) => AsyncStateView(
///     isLoading: state is HomeworkLoading,
///     error: state is HomeworkError ? state.message : null,
///     isEmpty: state is HomeworkLoaded && state.items.isEmpty,
///     onRetry: () => context.read<HomeworkCubit>().load(),
///     emptyIcon: Icons.assignment_outlined,
///     emptyTitle: 'No homework yet',
///     child: state is HomeworkLoaded
///         ? HomeworkList(items: state.items)
///         : const SizedBox.shrink(),
///   ),
/// );
/// ```
class AsyncStateView extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final VoidCallback? onRetry;

  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final Widget? emptyAction;

  /// Loaded content. Only shown when not loading, no error, and not empty.
  final Widget child;

  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.child,
    this.error,
    this.isEmpty = false,
    this.onRetry,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'Nothing here yet',
    this.emptySubtitle,
    this.emptyAction,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const LoadingView();
    if (error != null) return ErrorView(message: error!, onRetry: onRetry);
    if (isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
        action: emptyAction,
      );
    }
    return child;
  }
}

/// Full-screen inline loading overlay used during mutation actions
/// (submitting a complaint, sending a message, starting checkout) where the
/// caller wants to keep the surrounding UI visible but disabled.
class LoadingOverlay extends StatelessWidget {
  final bool show;
  final Widget child;
  final String? label;

  const LoadingOverlay({
    super.key,
    required this.show,
    required this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (show)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.25),
              child: Center(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        if (label != null) ...[
                          const SizedBox(width: 16),
                          Text(label!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
