import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/parent/data/models/parent_extra_models.dart';
import 'package:first_try/features/parent/data/models/parent_models.dart';
import 'package:first_try/features/parent/presentation/cubit/billing_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_cubit.dart';
import 'package:first_try/features/parent/presentation/cubit/parent_state.dart';
import 'package:first_try/features/parent/presentation/screens/billing/parent_invoice_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ParentInvoicesScreen extends StatefulWidget {
  const ParentInvoicesScreen({super.key});

  @override
  State<ParentInvoicesScreen> createState() => _ParentInvoicesScreenState();
}

class _ParentInvoicesScreenState extends State<ParentInvoicesScreen> {
  int? _studentId;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    context.read<BillingCubit>().load();
  }

  void _reload() =>
      context.read<BillingCubit>().load(studentId: _studentId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<BillingCubit, BillingState>(
        builder: (context, state) {
          if (state is BillingLoading || state is BillingInitial) {
            return const CardListSkeleton();
          }
          if (state is BillingError) {
            return ErrorView(message: state.message, onRetry: _reload);
          }
          if (state is! BillingLoaded) return const SizedBox.shrink();

          final filtered = _statusFilter == null
              ? state.invoices.invoices
              : state.invoices.invoices
                  .where((i) => i.status == _statusFilter)
                  .toList();

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Outstanding balance
                _OutstandingCard(
                    outstanding: state.invoices.outstanding),
                const SizedBox(height: 14),
                // Child filter (only shown when multiple children)
                _ChildFilterBar(
                  selected: _studentId,
                  onChanged: (id) {
                    setState(() => _studentId = id);
                    _reload();
                  },
                ),
                // Status filter
                _StatusFilterBar(
                  current: _statusFilter,
                  onChanged: (s) => setState(() => _statusFilter = s),
                ),
                const SizedBox(height: 8),
                // Invoice list
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No invoices',
                      subtitle: 'No invoices match this filter.',
                    ),
                  )
                else
                  for (final inv in filtered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InvoiceCard(invoice: inv),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Outstanding balance card ──────────────────────────────────────────────────

class _OutstandingCard extends StatelessWidget {
  final double outstanding;
  const _OutstandingCard({required this.outstanding});

  @override
  Widget build(BuildContext context) {
    final hasDue = outstanding > 0;
    final gradient = hasDue
        ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
        : [const Color(0xFF059669), const Color(0xFF0891B2)];

    return AppCard.glass(
      gradient: gradient,
      opacity: 0.92,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: Radii.smRadius,
          ),
          child: Icon(
            hasDue
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasDue ? 'Outstanding Balance' : 'All Paid Up',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                    .format(outstanding),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Filter bars ───────────────────────────────────────────────────────────────

class _ChildFilterBar extends StatelessWidget {
  final int? selected;
  final ValueChanged<int?> onChanged;
  const _ChildFilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentCubit, ParentState>(
      builder: (context, state) {
        if (state is! ParentLoaded) return const SizedBox.shrink();
        final children = state.profile.children;
        if (children.length <= 1) return const SizedBox.shrink();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            FilterPill(
              label: 'All',
              selected: selected == null,
              onSelected: (_) => onChanged(null),
            ),
            const SizedBox(width: 8),
            for (final c in children) ...[
              FilterPill(
                label: c.name.split(' ').first,
                selected: selected == c.id,
                onSelected: (_) => onChanged(c.id),
              ),
              const SizedBox(width: 8),
            ],
          ]),
        );
      },
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  const _StatusFilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = <(String?, String)>[
      (null, 'All'),
      ('pending', 'Pending'),
      ('partially_paid', 'Partial'),
      ('paid', 'Paid'),
      ('overdue', 'Overdue'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final e in entries) ...[
          FilterPill(
            label: e.$2,
            selected: current == e.$1,
            onSelected: (_) => onChanged(e.$1),
          ),
          const SizedBox(width: 8),
        ],
      ]),
    );
  }
}

// ── Invoice card ──────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppCard.surface(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<BillingCubit>(),
            child: ParentInvoiceDetailScreen(invoiceId: invoice.id),
          ),
        ));
      },
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: Radii.smRadius,
              ),
              child: Icon(Icons.receipt_long_rounded,
                  size: 16, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                invoice.studentName ?? 'Invoice #${invoice.id}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(
              label: _statusLabel(invoice.status),
              tone: _statusTone(invoice.status),
            ),
          ]),
          const SizedBox(height: 8),
          if (invoice.feePlan != null)
            Text(
              invoice.feePlan!,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.calendar_today_rounded,
                size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'Due ${_fmt(invoice.dueDate)}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                  .format(invoice.outstanding),
              style: TextStyle(
                  color: cs.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: cs.onSurfaceVariant),
          ]),
        ],
      ),
    );
  }

  String _statusLabel(String s) => switch (s) {
        'partially_paid' => 'Partial',
        _ => s[0].toUpperCase() + s.substring(1),
      };

  StatusTone _statusTone(String s) => switch (s) {
        'paid' => StatusTone.success,
        'overdue' => StatusTone.error,
        'partially_paid' => StatusTone.info,
        'cancelled' => StatusTone.neutral,
        _ => StatusTone.warning,
      };

  String _fmt(String iso) {
    try {
      return DateFormat('d MMM y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
