import 'package:first_try/core/services/json_cache.dart';
import 'package:first_try/core/services/storage_services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    // setMockInitialValues resets the mock platform, but StorageService caches
    // its SharedPreferences singleton as a static — so we also clear the
    // live instance to prevent state leaking between tests.
    SharedPreferences.setMockInitialValues({});
    await StorageService.clearAll();
  });

  group('JsonCache.write/read', () {
    test('round-trips a value', () async {
      await JsonCache.write('k', {'a': 1, 'b': 'two'});
      final raw = await JsonCache.readRaw('k');
      expect(raw, {'a': 1, 'b': 'two'});
    });

    test('returns null on miss', () async {
      expect(await JsonCache.readRaw('missing'), isNull);
    });

    test('TTL expiry returns null', () async {
      await JsonCache.write('k', 'v');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final hit = await JsonCache.readRaw(
        'k',
        ttl: const Duration(milliseconds: 1),
      );
      expect(hit, isNull);
    });

    test('TTL not expired returns value', () async {
      await JsonCache.write('k', 'v');
      final hit =
          await JsonCache.readRaw('k', ttl: const Duration(minutes: 5));
      expect(hit, 'v');
    });

    test('remove clears the entry', () async {
      await JsonCache.write('k', 'v');
      await JsonCache.remove('k');
      expect(await JsonCache.readRaw('k'), isNull);
    });

    test('malformed envelope returns null (no crash)', () async {
      SharedPreferences.setMockInitialValues(
        {'json_cache:k': 'not json'},
      );
      expect(await JsonCache.readRaw('k'), isNull);
    });
  });

  group('JsonCache.swr', () {
    test('caches fresh value on success', () async {
      var calls = 0;
      final value = await JsonCache.swr<int>(
        key: 'count',
        fetch: () async {
          calls++;
          return 7;
        },
        fromJson: (j) => j as int,
        toJson: (v) => v,
      );
      expect(value, 7);
      expect(calls, 1);

      // Second call — fetch still runs (no TTL), but cache is also populated.
      final value2 = await JsonCache.swr<int>(
        key: 'count',
        fetch: () async => 8,
        fromJson: (j) => j as int,
        toJson: (v) => v,
      );
      expect(value2, 8);
    });

    test('falls back to cache on network failure', () async {
      await JsonCache.write('count', 42);

      final value = await JsonCache.swr<int>(
        key: 'count',
        fetch: () async => throw Exception('offline'),
        fromJson: (j) => j as int,
        toJson: (v) => v,
      );
      expect(value, 42);
    });

    test('rethrows when no cache and fetch fails', () async {
      expect(
        () => JsonCache.swr<int>(
          key: 'count',
          fetch: () async => throw Exception('offline'),
          fromJson: (j) => j as int,
          toJson: (v) => v,
        ),
        throwsException,
      );
    });
  });

  group('JsonCache.cacheFirst', () {
    test('returns cached value when fresh', () async {
      await JsonCache.write('k', 10);
      final value = await JsonCache.cacheFirst<int>(
        key: 'k',
        ttl: const Duration(minutes: 5),
        fetch: () async => fail('should not fetch'),
        fromJson: (j) => j as int,
        toJson: (v) => v,
      );
      expect(value, 10);
    });

    test('fetches when cache is stale', () async {
      await JsonCache.write('k', 10);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final value = await JsonCache.cacheFirst<int>(
        key: 'k',
        ttl: const Duration(milliseconds: 1),
        fetch: () async => 20,
        fromJson: (j) => j as int,
        toJson: (v) => v,
      );
      expect(value, 20);
    });
  });
}
