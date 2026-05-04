import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/parent/data/models/parent_extra_models.dart';
import 'package:first_try/features/parent/presentation/cubit/billing_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ParentInvoiceDetailScreen extends StatelessWidget {
  final int invoiceId;
  const ParentInvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #$invoiceId',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<BillingCubit, BillingState>(
        builder: (context, state) {
          if (state is BillingLoading || state is BillingInitial) {
            return const CardListSkeleton();
          }
          if (state is BillingError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<BillingCubit>().load(),
            );
          }
          if (state is! BillingLoaded) return const SizedBox.shrink();

          final invoice = state.invoices.invoices
              .where((i) => i.id == invoiceId)
              .firstOrNull;
          if (invoice == null) {
            return const Center(child: Text('Invoice not found.'));
          }

          final relatedPayments = state.payments.payments
              .where((p) => p.invoiceId == invoiceId)
              .toList();

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DetailCard(invoice: invoice),
                  const SizedBox(height: 16),
                  if (relatedPayments.isNotEmpty) ...[
                    const _SectionTitle(title: 'Payment History'),
                    const SizedBox(height: 8),
                    for (final p in relatedPayments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PaymentRow(payment: p),
                      ),
                    const SizedBox(height: 16),
                  ],
                  if (invoice.isPayable)
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        label: state.isOpeningCheckout
                            ? 'Opening Stripe…'
                            : 'Pay ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(invoice.outstanding)}',
                        icon: Icons.lock_rounded,
                        loading: state.isOpeningCheckout,
                        onPressed: () =>
                            context.read<BillingCubit>().startCheckout(
                                  invoiceId: invoice.id,
                                  successUrl:
                                      'https://example.com/payments/success',
                                  cancelUrl:
                                      'https://example.com/payments/cancel',
                                ),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
              if (state.activeCheckout != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _CheckoutPollingBar(
                    session: state.activeCheckout!,
                    status: state.activeCheckoutStatus,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Detail card ───────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final InvoiceModel invoice;
  const _DetailCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard.surface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (invoice.studentName != null)
            Text(invoice.studentName!,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          if (invoice.feePlan != null) ...[
            const SizedBox(height: 4),
            Text(invoice.feePlan!,
                style: TextStyle(
                    fontSize: 13, color: cs.onSurfaceVariant)),
          ],
          if (invoice.schoolYear != null) ...[
            const SizedBox(height: 2),
            Text('Year ${invoice.schoolYear!}',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant)),
          ],
          const Divider(height: 28),
          _row('Total',
              NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                  .format(invoice.totalAmount)),
          const SizedBox(height: 8),
          _row(
              'Paid',
              NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                  .format(invoice.paidTotal)),
          const SizedBox(height: 8),
          _row(
            'Outstanding',
            NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                .format(invoice.outstanding),
            valueColor: invoice.outstanding > 0
                ? const Color(0xFFE11D48)
                : const Color(0xFF10B981),
            bold: true,
          ),
          const SizedBox(height: 8),
          _row('Due', _fmt(invoice.dueDate)),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor)),
      ],
    );
  }

  String _fmt(String iso) {
    try {
      return DateFormat('d MMM y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Payment row ───────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (payment.status) {
      'completed' => const Color(0xFF10B981),
      'failed' => const Color(0xFFE11D48),
      'refunded' => const Color(0xFF8B5CF6),
      _ => const Color(0xFFF59E0B),
    };

    return AppCard.surface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment.method.toUpperCase()} • ${payment.status[0].toUpperCase()}${payment.status.substring(1)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                if (payment.paidAt.isNotEmpty)
                  Text(_fmt(payment.paidAt),
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                .format(payment.amount),
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _fmt(String iso) {
    try {
      return DateFormat('d MMM y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

// ── Checkout polling bar ──────────────────────────────────────────────────────

class _CheckoutPollingBar extends StatelessWidget {
  final CheckoutSessionModel session;
  final CheckoutStatusModel? status;
  const _CheckoutPollingBar(
      {required this.session, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = status?.status ?? 'pending';
    final isTerminal = status?.isTerminal ?? false;
    final color = switch (s) {
      'completed' => const Color(0xFF10B981),
      'failed' => const Color(0xFFE11D48),
      'refunded' => const Color(0xFF8B5CF6),
      _ => cs.primary,
    };
    final label = switch (s) {
      'completed' => 'Payment completed!',
      'failed' => 'Payment failed.',
      'refunded' => 'Payment refunded.',
      _ => 'Awaiting payment in browser…',
    };

    return Material(
      elevation: 8,
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            if (!isTerminal)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: color),
              )
            else
              Icon(
                s == 'completed'
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                color: color,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontSize: 13)),
                  Text(
                    NumberFormat.currency(
                            symbol: '\$', decimalDigits: 2)
                        .format(session.amount),
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context
                  .read<BillingCubit>()
                  .dismissActiveCheckout(),
              child: Text(isTerminal ? 'Close' : 'Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
