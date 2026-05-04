import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/change_password_modal.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/profile_avatar_picker.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:first_try/features/student/data/models/student_models.dart';
import 'package:first_try/features/student/presentation/cubit/student_profile_cubit.dart';
import 'package:first_try/features/student/presentation/cubit/student_profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentProfileCubit, StudentProfileState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: switch (state) {
            StudentProfileLoading() ||
            StudentProfileInitial() =>
              const LoadingView(),
            StudentProfileError(:final message) => ErrorView(
                message: message,
                onRetry: () =>
                    context.read<StudentProfileCubit>().load()),
            StudentProfileLoaded(:final profile) =>
              _ProfileBody(profile: profile),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final StudentProfileModel profile;
  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar + name
        Center(
          child: Column(
            children: [
              ProfileAvatarPicker(displayName: profile.name),
              const SizedBox(height: 12),
              Text(
                profile.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                profile.email,
                style: TextStyle(
                    fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // School info
        _SectionCard(
          title: 'School Info',
          children: [
            _InfoRow(
                icon: Icons.school_rounded,
                label: 'Class',
                value: profile.className ?? '—'),
            _InfoRow(
                icon: Icons.group_rounded,
                label: 'Section',
                value: profile.section ?? '—'),
            _InfoRow(
                icon: Icons.calendar_month_rounded,
                label: 'School Year',
                value: profile.schoolYear ?? '—'),
          ],
        ),
        const SizedBox(height: 12),

        // Personal info
        _SectionCard(
          title: 'Personal Info',
          children: [
            _InfoRow(
                icon: Icons.phone_rounded,
                label: 'Phone',
                value: profile.phone ?? '—'),
            _InfoRow(
                icon: Icons.cake_rounded,
                label: 'Date of Birth',
                value: profile.dob ?? '—'),
            _InfoRow(
                icon: Icons.wc_rounded,
                label: 'Gender',
                value: profile.gender ?? '—'),
            _InfoRow(
                icon: Icons.home_rounded,
                label: 'Address',
                value: profile.address ?? '—'),
          ],
        ),
        const SizedBox(height: 24),

        // Change password
        OutlinedButton.icon(
          icon: const Icon(Icons.lock_outline_rounded),
          label: const Text('Change Password'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
                borderRadius: Radii.smRadius),
          ),
          onPressed: () => showChangePasswordModal(
            context,
            onSubmit: (current, next) async {
              try {
                await context.read<AuthCubit>().changePassword(
                      currentPassword: current,
                      newPassword: next,
                    );
                return null;
              } catch (e) {
                return e.toString();
              }
            },
          ),
        ),
        const SizedBox(height: 12),

        // Logout
        SizedBox(
          width: double.infinity,
          child: AppButton.danger(
            label: 'Log Out',
            icon: Icons.logout_rounded,
            onPressed: () => _confirmLogout(context),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _confirmLogout(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<AuthCubit>().logout();
    }
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.surface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
