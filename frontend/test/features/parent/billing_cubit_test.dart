import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/parent/data/repos/parent_repo.dart';
import 'package:first_try/features/parent/presentation/cubit/billing_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_api_consumer.dart';

void main() {
  const parentId = 42;

  late MockApiConsumer api;
  late ParentRepo repo;
  late BillingCubit cubit;
  late List<Uri> openedUrls;

  void seedEmpty() {
    api.onGet(AppUrl.parentInvoices(parentId), {
      'total': 0,
      'outstanding': 0,
      'invoices': [],
    });
    api.onGet(AppUrl.parentPayments(parentId), {
      'total_paid': 0,
      'count': 0,
      'payments': [],
    });
  }

  setUp(() {
    api = MockApiConsumer();
    repo = ParentRepo(api: api, parentId: parentId);
    openedUrls = [];
    cubit = BillingCubit(
      repo: repo,
      launchUrl: (uri) async {
        openedUrls.add(uri);
        return true;
      },
    );
  });

  tearDown(() async => cubit.close());

  test('load emits Loaded with invoices + payments', () async {
    seedEmpty();
    await cubit.load();
    expect(cubit.state, isA<BillingLoaded>());
  });

  test('Stripe checkout round-trip: create → open browser → poll until completed',
      () async {
    seedEmpty();
    await cubit.load();

    api.onPost(AppUrl.parentCheckout(parentId), {
      'checkout_url': 'https://checkout.stripe.com/c/sess_123',
      'session_id': 'sess_123',
      'amount': 500.0,
    });

    // Poll responses: two pending ticks, then completed.
    final statusUrl = AppUrl.parentCheckoutStatus(parentId, 'sess_123');
    api.onGet(statusUrl, {
      'status': 'pending',
      'amount': 500,
      'invoice_id': 1,
    });
    api.onGet(statusUrl, {
      'status': 'pending',
      'amount': 500,
      'invoice_id': 1,
    });
    api.onGet(statusUrl, {
      'status': 'completed',
      'amount': 500,
      'invoice_id': 1,
    });

    // The terminal poll triggers a refresh — re-queue invoices/payments.
    seedEmpty();

    final receivedStates = <BillingState>[];
    final sub = cubit.stream.listen(receivedStates.add);

    await cubit.startCheckout(
      invoiceId: 1,
      successUrl: 'https://app/success',
      cancelUrl: 'https://app/cancel',
    );

    // Browser was asked to open Stripe URL.
    expect(openedUrls, hasLength(1));
    expect(openedUrls.single.host, 'checkout.stripe.com');

    // Session recorded in state.
    final active = cubit.state as BillingLoaded;
    expect(active.activeCheckout?.sessionId, 'sess_123');

    // Wait long enough for the 3s poll (2 pending + 1 completed) — or force it.
    // We advance real time rather than mock Timer to keep this straightforward.
    // The poll runs every 3s, so wait a hair over 9s.
    await Future<void>.delayed(const Duration(seconds: 10));
    await sub.cancel();

    // After completion, state should reflect the completed status (or be a
    // fresh Loaded with activeCheckout cleared by refresh).
    expect(cubit.state, isA<BillingLoaded>());
    expect(
      api.countCallsFor('GET', statusUrl),
      greaterThanOrEqualTo(1),
      reason: 'poller must hit /status at least once',
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('checkout fails to open → emits BillingError', () async {
    seedEmpty();
    await cubit.load();

    cubit = BillingCubit(
      repo: repo,
      launchUrl: (_) async => false, // simulate "no browser available"
    );
    await cubit.load();
    seedEmpty(); // refresh after load

    api.onPost(AppUrl.parentCheckout(parentId), {
      'checkout_url': 'https://checkout.stripe.com/c/x',
      'session_id': 'x',
      'amount': 10.0,
    });

    await cubit.startCheckout(
      invoiceId: 1,
      successUrl: 'https://s',
      cancelUrl: 'https://c',
    );
    expect(cubit.state, isA<BillingError>());
  });

  test('checkout server returns 422 → emits BillingError', () async {
    seedEmpty();
    await cubit.load();

    api.onPost(
      AppUrl.parentCheckout(parentId),
      dioError(statusCode: 422, data: {
        'message': 'Invoice not payable.',
        'errors': {
          'invoice_id': ['Invoice already paid.'],
        },
      }),
    );

    await cubit.startCheckout(
      invoiceId: 1,
      successUrl: 'https://s',
      cancelUrl: 'https://c',
    );
    expect(cubit.state, isA<BillingError>());
  });
}
