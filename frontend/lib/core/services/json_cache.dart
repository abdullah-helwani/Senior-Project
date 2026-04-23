import 'dart:convert';

import 'package:first_try/core/services/storage_services.dart';

/// Lightweight JSON cache on top of shared_preferences.
///
/// Use for read-heavy screens that should keep working offline
/// (schedule, marks, homework list, invoices, ...).
///
/// Stored shape: `{ "t": <epochMs>, "v": <raw json> }`.
///
/// ### Usage
///
/// ```dart
/// // Cache-first fetch, stale-OK, revalidate in background:
/// Future<List<MarkModel>> getMarks() async {
///   return JsonCache.swr<List<MarkModel>>(
///     key: 'student_marks',
///     ttl: const Duration(minutes: 10),
///     fetch: () async {
///       final res = await api.getApi(AppUrl.studentMarks);
///       return (res as List).map((e) => MarkModel.fromJson(e)).toList();
///     },
///     fromJson: (j) => (j as List)
///         .map((e) => MarkModel.fromJson(e as Map<String, dynamic>))
///         .toList(),
///     toJson: (marks) => marks.map((m) => m.toJson()).toList(),
///   );
/// }
/// ```
class JsonCache {
  JsonCache._();

  static const _prefix = 'json_cache:';

  /// Write a JSON-serializable value.
  static Future<void> write(String key, Object value) async {
    final env = jsonEncode({
      't': DateTime.now().millisecondsSinceEpoch,
      'v': value,
    });
    await StorageService.saveString(_prefix + key, env);
  }

  /// Raw read. Returns null if missing or malformed.
  /// If [ttl] is provided and the entry is older, returns null (treated as miss).
  static Future<dynamic> readRaw(String key, {Duration? ttl}) async {
    final raw = await StorageService.getString(_prefix + key);
    if (raw == null) return null;
    try {
      final env = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (env['t'] as num?)?.toInt() ?? 0;
      if (ttl != null) {
        final age = DateTime.now().millisecondsSinceEpoch - ts;
        if (age > ttl.inMilliseconds) return null;
      }
      return env['v'];
    } catch (_) {
      return null;
    }
  }

  /// Typed read. Returns null on miss / decode error.
  static Future<T?> read<T>(
    String key, {
    required T Function(dynamic json) fromJson,
    Duration? ttl,
  }) async {
    final v = await readRaw(key, ttl: ttl);
    if (v == null) return null;
    try {
      return fromJson(v);
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String key) =>
      StorageService.remove(_prefix + key);

  /// Stale-while-revalidate.
  ///
  /// 1. Tries the network.
  /// 2. On success → caches and returns fresh.
  /// 3. On failure → falls back to cached value (ignoring [ttl]) if present,
  ///    otherwise rethrows.
  ///
  /// [toJson] converts [T] to a JSON-serializable structure before writing.
  static Future<T> swr<T>({
    required String key,
    required Future<T> Function() fetch,
    required T Function(dynamic json) fromJson,
    required Object Function(T value) toJson,
    Duration? ttl,
  }) async {
    try {
      final fresh = await fetch();
      await write(key, toJson(fresh));
      return fresh;
    } catch (e) {
      final cached = await read<T>(key, fromJson: fromJson);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Cache-first. Returns cached value immediately if fresh (< [ttl]).
  /// Otherwise fetches, caches, and returns fresh. Falls back to stale cache
  /// on network error.
  static Future<T> cacheFirst<T>({
    required String key,
    required Duration ttl,
    required Future<T> Function() fetch,
    required T Function(dynamic json) fromJson,
    required Object Function(T value) toJson,
  }) async {
    final hit = await read<T>(key, fromJson: fromJson, ttl: ttl);
    if (hit != null) return hit;
    return swr<T>(
      key: key,
      fetch: fetch,
      fromJson: fromJson,
      toJson: toJson,
      ttl: ttl,
    );
  }
}
