import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:first_try/features/parent/data/models/parent_models.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Profile'),
              Tab(text: 'My Children'),
            ],
          ),
        ),
        body: BlocBuilder<ParentCubit, ParentState>(
          builder: (context, state) {
            if (state is! ParentLoaded) return const SizedBox.shrink();
            return TabBarView(
              children: [
                _ProfileTab(profile: state.profile),
                _ChildrenTab(children: state.profile.children),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Profile tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final ParentProfileModel profile;
  const _ProfileTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(children: [
        // Avatar
        CircleAvatar(
          radius: 44,
          backgroundColor: cs.primaryContainer,
          child: Text(
            profile.name[0],
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: cs.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(profile.name,
            style:
                Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        Text(profile.email,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),

        // Info cards
        _ProfileCard(
          children: [
            _InfoTile(icon: Icons.person_rounded, label: 'Full Name', value: profile.name),
            _InfoTile(icon: Icons.email_rounded, label: 'Email', value: profile.email),
            if (profile.phone != null)
              _InfoTile(icon: Icons.phone_rounded, label: 'Phone', value: profile.phone!),
            _InfoTile(
              icon: Icons.child_care_rounded,
              label: 'Children',
              value: '${profile.children.length} registered',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Actions
        _ProfileCard(
          children: [
            _ActionTile(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              color: cs.primary,
              onTap: () => _showChangePasswordSheet(context),
            ),
            _ActionTile(
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: Colors.red.shade600,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ]),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true, _obscure2 = true, _obscure3 = true;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Change Password',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _PassField(
            controller: _current,
            label: 'Current Password',
            obscure: _obscure1,
            onToggle: () => setState(() => _obscure1 = !_obscure1),
          ),
          const SizedBox(height: 12),
          _PassField(
            controller: _newPass,
            label: 'New Password',
            obscure: _obscure2,
            onToggle: () => setState(() => _obscure2 = !_obscure2),
            validator: (v) => (v ?? '').length < 6 ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 12),
          _PassField(
            controller: _confirm,
            label: 'Confirm New Password',
            obscure: _obscure3,
            onToggle: () => setState(() => _obscure3 = !_obscure3),
            validator: (v) => v != _newPass.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated (demo)')),
                  );
                }
              },
              child: const Text('Update Password'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PassField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
            onPressed: onToggle,
          ),
        ),
      );
}

// ── Children tab ──────────────────────────────────────────────────────────────

class _ChildrenTab extends StatelessWidget {
  final List<ChildSummaryModel> children;
  const _ChildrenTab({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Center(
        child: Text('No children registered.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: children.length,
      separatorBuilder: (context, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _ChildCard(child: children[i]),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final ChildSummaryModel child;
  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primaryContainer,
            child: Text(child.name[0],
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(child.name,
                  style:
                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text('${child.className} — ${child.section}',
                  style:
                      TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(children: [
          _StatChip(
            label: 'Avg Score',
            value: '${child.averageScore.toStringAsFixed(0)}%',
            color: cs.primary,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Attendance',
            value: '${child.attendancePercent.toStringAsFixed(0)}%',
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Pending HW',
            value: '${child.pendingHomeworkCount}',
            color: Colors.orange.shade600,
          ),
        ]),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
          ]),
        ),
      );
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final List<Widget> children;
  const _ProfileCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Divider(height: 1, indent: 56, color: cs.outlineVariant);
          }
          return children[i ~/ 2];
        }),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: cs.primary, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right_rounded, color: color),
        onTap: onTap,
      );
}
