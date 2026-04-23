import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:first_try/features/parent/data/models/parent_extra_models.dart';
import 'package:first_try/features/parent/data/repos/parent_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

// ── States ───────────────────────────────────────────────────────────────────

sealed class BillingState extends Equatable {
  const BillingState();
  @override
  List<Object?> get props => [];
}

class BillingInitial extends BillingState {
  const BillingInitial();
}

class BillingLoading extends BillingState {
  const BillingLoading();
}

/// Loaded snapshot of invoices + payments, plus any in-flight checkout.
class BillingLoaded extends BillingState {
  final InvoicesSummaryModel invoices;
  final PaymentsHistoryModel payments;

  /// When the user triggers Stripe checkout, we track the session here so
  /// the UI can render a "waiting for payment" view and the cubit can poll
  /// the status until it's terminal.
  final CheckoutSessionModel? activeCheckout;
  final CheckoutStatusModel? activeCheckoutStatus;
  final bool isOpeningCheckout;

  const BillingLoaded({
    required this.invoices,
    required this.payments,
    this.activeCheckout,
    this.activeCheckoutStatus,
    this.isOpeningCheckout = false,
  });

  BillingLoaded copyWith({
    InvoicesSummaryModel? invoices,
    PaymentsHistoryModel? payments,
    CheckoutSessionModel? activeCheckout,
    bool clearCheckout = false,
    CheckoutStatusModel? activeCheckoutStatus,
    bool? isOpeningCheckout,
  }) =>
      BillingLoaded(
        invoices: invoices ?? this.invoices,
        payments: payments ?? this.payments,
        activeCheckout: clearCheckout ? null : (activeCheckout ?? this.activeCheckout),
        activeCheckoutStatus: clearCheckout
            ? null
            : (activeCheckoutStatus ?? this.activeCheckoutStatus),
        isOpeningCheckout: isOpeningCheckout ?? this.isOpeningCheckout,
      );

  @override
  List<Object?> get props => [
        invoices,
        payments,
        activeCheckout,
        activeCheckoutStatus,
        isOpeningCheckout,
      ];
}

class BillingError extends BillingState {
  final String message;
  const BillingError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ────────────────────────────────────────────────────────────────────

class BillingCubit extends Cubit<BillingState> {
  final ParentRepo repo;

  /// Launcher for opening the Stripe checkout URL in a browser. Overridable
  /// for tests.
  final Future<bool> Function(Uri url) launchUrl;

  Timer? _poller;

  BillingCubit({
    required this.repo,
    Future<bool> Function(Uri url)? launchUrl,
  })  : launchUrl = launchUrl ?? _defaultLaunchUrl,
        super(const BillingInitial());

  static Future<bool> _defaultLaunchUrl(Uri url) =>
      launchUrl_(url, mode: LaunchMode.externalApplication);

  Future<void> load({int? studentId}) async {
    emit(const BillingLoading());
    try {
      final results = await Future.wait([
        repo.getInvoices(studentId: studentId),
        repo.getPayments(studentId: studentId),
      ]);
      emit(BillingLoaded(
        invoices: results[0] as InvoicesSummaryModel,
        payments: results[1] as PaymentsHistoryModel,
      ));
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }

  Future<void> refresh({int? studentId}) => load(studentId: studentId);

  /// End-to-end: creates a Stripe Checkout Session for [invoiceId], opens the
  /// returned URL in an external browser, then polls `/status` every 3s until
  /// terminal (completed/failed/refunded). On completion, refreshes invoices +
  /// payments so the UI reflects the new state.
  ///
  /// [successUrl] / [cancelUrl] are redirect targets Stripe bounces to after
  /// the hosted Checkout page; they can be any valid URL — the app never
  /// actually loads them (we poll /status instead).
  Future<void> startCheckout({
    required int invoiceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final s = state;
    if (s is! BillingLoaded) return;
    emit(s.copyWith(isOpeningCheckout: true));

    CheckoutSessionModel session;
    try {
      session = await repo.createCheckout(
        invoiceId: invoiceId,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );
    } catch (e) {
      emit(s.copyWith(isOpeningCheckout: false));
      emit(BillingError(e.toString()));
      return;
    }

    // Open Stripe-hosted checkout in the browser.
    final uri = Uri.parse(session.checkoutUrl);
    final opened = await launchUrl(uri);
    if (!opened) {
      emit(s.copyWith(isOpeningCheckout: false));
      emit(const BillingError('Could not open the checkout page.'));
      return;
    }

    emit(s.copyWith(
      activeCheckout: session,
      isOpeningCheckout: false,
    ));

    _startPolling(session.sessionId);
  }

  void _startPolling(String sessionId) {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final status = await repo.getCheckoutStatus(sessionId);
        final s = state;
        if (s is! BillingLoaded) {
          _poller?.cancel();
          return;
        }
        emit(s.copyWith(activeCheckoutStatus: status));
        if (status.isTerminal) {
          _poller?.cancel();
          // Refresh so paid invoices and new payment rows appear.
          await refresh();
        }
      } catch (_) {
        // Transient errors while polling shouldn't tear state down —
        // the next tick will try again.
      }
    });
  }

  /// Manually dismiss an active checkout (e.g. user navigates away).
  void dismissActiveCheckout() {
    _poller?.cancel();
    final s = state;
    if (s is BillingLoaded) {
      emit(s.copyWith(clearCheckout: true));
    }
  }

  @override
  Future<void> close() {
    _poller?.cancel();
    return super.close();
  }
}

/// Indirection so the named import doesn't collide with the cubit's
/// `launchUrl` field.
Future<bool> launchUrl_(Uri url, {LaunchMode mode = LaunchMode.platformDefault}) =>
    launchUrl(url, mode: mode);
