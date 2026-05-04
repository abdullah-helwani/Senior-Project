import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/parent/data/models/parent_extra_models.dart';
import 'package:first_try/features/parent/presentation/cubit/billing_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ParentPaymentsScreen extends StatefulWidget {
  const ParentPaymentsScreen({super.key});

  @override
  State<ParentPaymentsScreen> createState() => _ParentPaymentsScreenState();
}

class _ParentPaymentsScreenState extends State<ParentPaymentsScreen> {
  String? _methodFilter;

  @override
  void initState() {
    super.initState();
    final s = context.read<BillingCubit>().state;
    if (s is! BillingLoaded) {
      context.read<BillingCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<BillingCubit, BillingState>(
        builder: (context, state) {
          if (state is BillingLoading || state is BillingInitial) {
            return const CardListSkeleton(showFilter: true);
          }
          if (state is BillingError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<BillingCubit>().load(),
            );
          }
          if (state is! BillingLoaded) return const SizedBox.shrink();

          final all = state.payments.payments;
          final filtered = _methodFilter == null
              ? all
              : all.where((p) => p.method == _methodFilter).toList();

          return RefreshIndicator(
            onRefresh: () => context.read<BillingCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(
                  totalPaid: state.payments.totalPaid,
                  count: state.payments.count,
                ),
                const SizedBox(height: 12),
                _MethodFilter(
                  current: _methodFilter,
                  onChanged: (m) => setState(() => _methodFilter = m),
                ),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyState(
                      icon: Icons.payments_outlined,
                      title: 'No payments yet',
                      subtitle: 'Payments will appear here.',
                    ),
                  )
                else
                  for (final p in filtered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PaymentTile(payment: p),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double totalPaid;
  final int count;
  const _SummaryCard({required this.totalPaid, required this.count});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppCard.glass(
      gradient: palette.brandGradient,
      opacity: 0.92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: Radii.smRadius,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Total Paid',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ]),
          const SizedBox(height: 14),
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                .format(totalPaid),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '$count payment${count == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Method filter ─────────────────────────────────────────────────────────────

class _MethodFilter extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  const _MethodFilter({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = <(String?, String)>[
      (null, 'All'),
      ('card', 'Card'),
      ('cash', 'Cash'),
      ('transfer', 'Transfer'),
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

// ── Payment tile ──────────────────────────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = _statusTone(payment.status);

    return AppCard.surface(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: Radii.smRadius,
          ),
          child: Icon(_methodIcon(payment.method),
              color: cs.onPrimaryContainer, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.studentName ?? 'Invoice #${payment.invoiceId}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(children: [
                Text(
                  payment.method.toUpperCase(),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                StatusPill(label: _statusLabel(payment.status), tone: tone),
                if (payment.paidAt.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    _fmt(payment.paidAt),
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ]),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          NumberFormat.currency(symbol: '\$', decimalDigits: 2)
              .format(payment.amount),
          style: TextStyle(
              fontWeight: FontWeight.w800, color: cs.primary, fontSize: 15),
        ),
      ]),
    );
  }

  StatusTone _statusTone(String s) => switch (s) {
        'completed' => StatusTone.success,
        'failed' => StatusTone.error,
        'refunded' => StatusTone.info,
        _ => StatusTone.warning,
      };

  String _statusLabel(String s) =>
      s[0].toUpperCase() + s.substring(1);

  IconData _methodIcon(String m) => switch (m) {
        'cash' => Icons.attach_money_rounded,
        'transfer' => Icons.account_balance_rounded,
        _ => Icons.credit_card_rounded,
      };

  String _fmt(String iso) {
    try {
      return DateFormat('d MMM y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
