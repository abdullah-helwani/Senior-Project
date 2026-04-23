import 'package:first_try/core/services/poller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fires immediately on start', () async {
    var calls = 0;
    final poller = Poller(
      interval: const Duration(seconds: 60),
      task: () async => calls++,
    );
    await poller.start();
    expect(calls, 1);
    poller.close();
  });

  test('fires on interval', () async {
    var calls = 0;
    final poller = Poller(
      interval: const Duration(milliseconds: 40),
      task: () async => calls++,
    );
    await poller.start();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    poller.close();
    expect(calls, greaterThanOrEqualTo(3)); // 1 immediate + ~3 ticks
  });

  test('stop halts further ticks', () async {
    var calls = 0;
    final poller = Poller(
      interval: const Duration(milliseconds: 30),
      task: () async => calls++,
    );
    await poller.start();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    poller.stop();
    final frozen = calls;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(calls, frozen);
    poller.close();
  });

  test('task errors are swallowed and loop keeps running', () async {
    var calls = 0;
    Object? received;
    final poller = Poller(
      interval: const Duration(milliseconds: 20),
      onError: (e, _) => received = e,
      task: () async {
        calls++;
        if (calls == 1) throw Exception('boom');
      },
    );
    await poller.start();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    poller.close();
    expect(calls, greaterThanOrEqualTo(2));
    expect(received, isNotNull);
  });

  test('refreshNow triggers without disturbing schedule', () async {
    var calls = 0;
    final poller = Poller(
      interval: const Duration(seconds: 60),
      task: () async => calls++,
    );
    await poller.start(); // 1
    await poller.refreshNow(); // 2
    await poller.refreshNow(); // 3
    expect(calls, 3);
    poller.close();
  });

  test('close prevents further starts', () async {
    var calls = 0;
    final poller = Poller(
      interval: const Duration(milliseconds: 30),
      task: () async => calls++,
    );
    poller.close();
    await poller.start();
    expect(calls, 0);
  });
}
