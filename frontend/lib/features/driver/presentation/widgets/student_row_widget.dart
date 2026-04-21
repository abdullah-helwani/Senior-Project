import 'package:first_try/features/driver/data/models/driver_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentRowWidget extends StatelessWidget {
  final StudentTripModel student;
  final bool isLoading;
  final VoidCallback onBoarded;
  final VoidCallback onDropped;

  const StudentRowWidget({
    super.key,
    required this.student,
    required this.isLoading,
    required this.onBoarded,
    required this.onDropped,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer,
            child: Text(
              student.studentName.characters.first.toUpperCase(),
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + stop + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.studentName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 13, color: cs.outline),
                    const SizedBox(width: 2),
                    Text(
                      student.stopName,
                      style: TextStyle(fontSize: 12, color: cs.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _StatusBadge(student: student),
              ],
            ),
          ),

          // Action buttons
          if (!isLoading) _ActionButtons(student: student, onBoarded: onBoarded, onDropped: onDropped)
          else const SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final StudentTripModel student;
  const _StatusBadge({required this.student});

  @override
  Widget build(BuildContext context) {
    switch (student.status) {
      case 'boarded':
        final time = student.boardedAt != null
            ? DateFormat('h:mm a').format(student.boardedAt!)
            : '';
        return _Chip(
            label: 'Boarded $time',
            bg: Colors.green.shade50,
            fg: Colors.green.shade700,
            icon: Icons.check_circle_rounded);
      case 'dropped':
        final time = student.droppedAt != null
            ? DateFormat('h:mm a').format(student.droppedAt!)
            : '';
        return _Chip(
            label: 'Dropped $time',
            bg: Colors.blue.shade50,
            fg: Colors.blue.shade700,
            icon: Icons.home_rounded);
      default:
        return _Chip(
            label: 'Not boarded',
            bg: Colors.grey.shade100,
            fg: Colors.grey.shade600,
            icon: Icons.radio_button_unchecked_rounded);
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;

  const _Chip(
      {required this.label,
      required this.bg,
      required this.fg,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final StudentTripModel student;
  final VoidCallback onBoarded;
  final VoidCallback onDropped;

  const _ActionButtons({
    required this.student,
    required this.onBoarded,
    required this.onDropped,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (student.status == 'not_boarded')
          _ActionBtn(
            label: 'Boarded',
            color: Colors.green.shade600,
            onTap: onBoarded,
          ),
        if (student.status == 'boarded') ...[
          _ActionBtn(
            label: 'Dropped',
            color: cs.primary,
            onTap: onDropped,
          ),
        ],
        if (student.status == 'dropped')
          Icon(Icons.check_circle_rounded,
              color: Colors.blue.shade400, size: 28),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(label),
      ),
    );
  }
}
