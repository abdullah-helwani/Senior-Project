import 'package:dio/dio.dart';
import 'package:first_try/core/api/dio_consumer.dart';
import 'package:first_try/core/widgets/shared/change_password_modal.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/features/auth/data/repos/auth_repo.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:first_try/features/driver/data/models/driver_models.dart';
import 'package:first_try/features/driver/presentation/cubit/driver_profile_cubit.dart';
import 'package:first_try/features/driver/presentation/cubit/driver_profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: BlocBuilder<DriverProfileCubit, DriverProfileState>(
          builder: (context, state) {
            if (state is DriverProfileLoading || state is DriverProfileInitial) {
              return const LoadingView();
            }
            if (state is DriverProfileError) {
              return ErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<DriverProfileCubit>().loadProfile(),
              );
            }
            if (state is DriverProfileLoaded) {
              return _ProfileContent(profile: state.profile);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final DriverProfileModel profile;
  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        // ── Avatar + name ────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  profile.name.isNotEmpty
                      ? profile.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bus Driver',
                style: TextStyle(color: cs.outline, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Contact info ─────────────────────────────────────────────────
        _SectionCard(
          title: 'Contact Information',
          children: [
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: profile.email),
            _InfoRow(icon: Icons.phone_outlined,  label: 'Phone', value: profile.phone.isNotEmpty ? profile.phone : '—'),
          ],
        ),
        const SizedBox(height: 16),

        // ── Assigned buses ───────────────────────────────────────────────
        _SectionCard(
          title: 'Assigned Buses',
          children: profile.buses.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No buses assigned',
                        style: TextStyle(color: cs.outline)),
                  ),
                ]
              : profile.buses
                  .map((b) => _BusRow(bus: b))
                  .toList(),
        ),
        const SizedBox(height: 32),

        // ── Actions ──────────────────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: () => _openChangePassword(context),
          icon: const Icon(Icons.lock_outline_rounded),
          label: const Text('Change Password'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),

        FilledButton.icon(
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Logout'),
          style: FilledButton.styleFrom(
            backgroundColor: cs.errorContainer,
            foregroundColor: cs.onErrorContainer,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  void _openChangePassword(BuildContext context) {
    final repo = AuthRepo(api: DioConsumer(dio: Dio()));
    showChangePasswordModal(
      context,
      onSubmit: (current, newPw) async {
        try {
          await repo.changePassword(
              currentPassword: current, newPassword: newPw);
          return null;
        } catch (e) {
          return e.toString();
        }
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthCubit>().logout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable card ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(children: children),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: cs.outline)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusRow extends StatelessWidget {
  final BusModel bus;
  const _BusRow({required this.bus});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.directions_bus_rounded,
                size: 20, color: cs.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bus.plate,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (bus.model != null)
                  Text(bus.model!,
                      style:
                          TextStyle(fontSize: 12, color: cs.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
