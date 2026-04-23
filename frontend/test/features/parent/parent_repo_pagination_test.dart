import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/parent/data/repos/parent_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_api_consumer.dart';

void main() {
  const parentId = 7;
  late MockApiConsumer api;
  late ParentRepo repo;

  setUp(() {
    api = MockApiConsumer();
    repo = ParentRepo(api: api, parentId: parentId);
  });

  group('messages pagination', () {
    test('handles Laravel {data:[...]} paginator shape', () async {
      api.onGet(AppUrl.parentMessages(parentId), {
        'data': [
          _message(1, 'Hi'),
          _message(2, 'Follow-up'),
        ],
        'meta': {'current_page': 1, 'last_page': 3, 'per_page': 2, 'total': 5},
        'links': {'next': '...'},
      });

      final msgs = await repo.getMessages(page: 1, perPage: 2);
      expect(msgs, hasLength(2));
      expect(msgs.first.subject, 'Hi');

      final call = api.lastCallFor('GET', AppUrl.parentMessages(parentId));
      expect(call!.queryParameters, {'page': 1, 'per_page': 2});
    });

    test('handles raw list shape', () async {
      api.onGet(AppUrl.parentMessages(parentId), [_message(9, 'Flat')]);
      final msgs = await repo.getMessages();
      expect(msgs, hasLength(1));
      expect(msgs.single.subject, 'Flat');
    });

    test('handles empty payload', () async {
      api.onGet(AppUrl.parentMessages(parentId), {'data': []});
      final msgs = await repo.getMessages();
      expect(msgs, isEmpty);
    });
  });

  group('invoices / payments wrappers', () {
    test('parses wrapped invoices summary', () async {
      api.onGet(AppUrl.parentInvoices(parentId), {
        'total': 2,
        'outstanding': 150.0,
        'invoices': [
          _invoice(1, outstanding: 50),
          _invoice(2, outstanding: 100, status: 'paid'),
        ],
      });

      final summary = await repo.getInvoices();
      expect(summary.total, 2);
      expect(summary.outstanding, 150.0);
      expect(summary.invoices, hasLength(2));
      expect(summary.invoices.first.isPayable, isTrue);
      expect(summary.invoices[1].isPayable, isFalse); // status=paid
    });

    test('parses payments history', () async {
      api.onGet(AppUrl.parentPayments(parentId), {
        'total_paid': 300.0,
        'count': 2,
        'payments': [
          _payment(1, 100),
          _payment(2, 200),
        ],
      });
      final history = await repo.getPayments();
      expect(history.totalPaid, 300.0);
      expect(history.count, 2);
      expect(history.payments, hasLength(2));
    });

    test('forwards filters as query params', () async {
      api.onGet(AppUrl.parentPayments(parentId), {
        'total_paid': 0,
        'count': 0,
        'payments': [],
      });
      await repo.getPayments(
        studentId: 5,
        method: 'card',
        paidFrom: '2025-01-01',
      );
      final call = api.lastCallFor('GET', AppUrl.parentPayments(parentId))!;
      expect(call.queryParameters, {
        'student_id': 5,
        'method': 'card',
        'paid_from': '2025-01-01',
      });
    });
  });
}

Map<String, dynamic> _message(int id, String subject) => {
      'id': id,
      'sender_id': 1,
      'receiver_id': 2,
      'subject': subject,
      'body': 'body',
      'read_at': null,
      'created_at': '2025-01-01T00:00:00Z',
    };

Map<String, dynamic> _invoice(
  int id, {
  double outstanding = 0,
  String status = 'pending',
}) =>
    {
      'invoice_id': id,
      'student': {'id': 3, 'name': 'Kid'},
      'fee_plan': 'Standard',
      'school_year': '2024-2025',
      'due_date': '2025-06-30',
      'totalamount': 500.0,
      'paid_total': 500.0 - outstanding,
      'outstanding': outstanding,
      'status': status,
    };

Map<String, dynamic> _payment(int id, double amount) => {
      'payment_id': id,
      'invoice_id': 1,
      'amount': amount,
      'method': 'card',
      'status': 'completed',
      'stripe_session_id': 'cs_$id',
      'paidat': '2025-02-01T12:00:00Z',
    };
