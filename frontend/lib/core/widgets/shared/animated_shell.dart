import 'package:first_try/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Drop-in replacement for [IndexedStack] that cross-fades between tabs.
/// All children remain in the tree (keeping their state / cubits alive);
/// only the active child is visible and accepts pointer events.
class AnimatedShell extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const AnimatedShell({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<AnimatedShell> createState() => _AnimatedShellState();
}

class _AnimatedShellState extends State<AnimatedShell> {
  int _previous = 0;

  @override
  void didUpdateWidget(AnimatedShell old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _previous = old.index;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        final active = i == widget.index;
        return AnimatedOpacity(
          opacity: active ? 1.0 : 0.0,
          duration: Motion.fast,
          curve: Curves.easeIn,
          child: IgnorePointer(
            ignoring: !active,
            child: widget.children[i],
          ),
        );
      }),
    );
  }
}
