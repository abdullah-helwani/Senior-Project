import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_salary_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TeacherSalaryScreen extends StatefulWidget {
  const TeacherSalaryScreen({super.key});

  @override
  State<TeacherSalaryScreen> createState() => _TeacherSalaryScreenState();
}

class _TeacherSalaryScreenState extends State<TeacherSalaryScreen> {
  String? _year;

  @override
  void initState() {
    super.initState();
    context.read<TeacherSalaryCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final years = _yearOptions();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter by year',
            onSelected: (v) {
              setState(() => _year = v);
              context.read<TeacherSalaryCubit>().load(year: v);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All years')),
              for (final y in years)
                PopupMenuItem(value: y, child: Text(y)),
            ],
          ),
        ],
      ),
      body: BlocBuilder<TeacherSalaryCubit, TeacherSalaryState>(
        builder: (context, state) {
          if (state is TeacherSalaryLoading || state is TeacherSalaryInitial) {
            return const CardListSkeleton();
          }
          if (state is TeacherSalaryError) {
            return ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<TeacherSalaryCubit>().load(year: _year),
            );
          }
          if (state is! TeacherSalaryLoaded) return const SizedBox.shrink();

          final s = state.summary;
          return RefreshIndicator(
            onRefresh: () =>
                context.read<TeacherSalaryCubit>().load(year: _year),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(
                  totalPaid: s.totalPaid,
                  count: s.count,
                  yearFilter: state.yearFilter,
                ),
                const SizedBox(height: 16),
                if (s.payments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyState(
                      icon: Icons.payments_outlined,
                      title: 'No payments yet',
                      subtitle: 'Salary payments will appear here.',
                    ),
                  )
                else
                  for (final p in s.payments)
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

  List<String> _yearOptions() {
    final now = DateTime.now().year;
    return [for (var y = now; y >= now - 4; y--) '$y'];
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalPaid;
  final int count;
  final String? yearFilter;
  const _SummaryCard(
      {required this.totalPaid,
      required this.count,
      required this.yearFilter});

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
            Expanded(
              child: Text(
                yearFilter == null ? 'Total Paid' : 'Total Paid in $yearFilter',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                .format(totalPaid),
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '$count payment${count == 1 ? '' : 's'}',
            style: const TextStyle(
                color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final SalaryPaymentModel payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.surface(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: Radii.smRadius,
          ),
          child: Icon(Icons.payments_rounded,
              color: cs.onPrimaryContainer, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fmtMonth(payment.periodMonth),
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              if (payment.paidAt != null)
                Text(
                  'Paid ${_fmtDate(payment.paidAt!)}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
        Text(
          NumberFormat.currency(symbol: '\$', decimalDigits: 2)
              .format(payment.amount),
          style: TextStyle(
              fontWeight: FontWeight.w800, color: cs.primary, fontSize: 15),
        ),
      ]),
    );
  }

  String _fmtMonth(String iso) {
    try {
      return DateFormat('MMMM y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat('d MMM y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
