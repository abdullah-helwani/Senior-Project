import 'dart:async';

/// Repeats an async task on a fixed interval. Use for lightweight live-refresh
/// (bus location on the parent's child-tracking screen, unread notifications
/// badge, live trip status) until the backend exposes websockets.
///
/// Contract:
///  • Calls [task] once immediately on [start] (opt out with [immediate: false]).
///  • Runs task sequentially — a slow response will not stack up concurrent calls.
///  • Silently swallows task errors so one bad poll doesn't kill the loop.
///  • Safe to [stop]/[start] repeatedly.
///  • [close] releases the timer and should be called from cubit `close()`.
///
/// ### Usage
///
/// ```dart
/// final _busPoller = Poller(
///   interval: const Duration(seconds: 5),
///   task: () async {
///     final events = await repo.getBusEvents(childId: id);
///     emit(state.withBusEvents(events));
///   },
/// );
///
/// void onOpen()  => _busPoller.start();
/// void onClose() => _busPoller.stop();
///
/// @override
/// Future<void> close() async {
///   _busPoller.close();
///   return super.close();
/// }
/// ```
class Poller {
  final Duration interval;
  final Future<void> Function() task;
  final void Function(Object error, StackTrace stack)? onError;

  Timer? _timer;
  bool _running = false;
  bool _closed = false;

  Poller({
    required this.interval,
    required this.task,
    this.onError,
  });

  bool get isActive => _timer != null;

  Future<void> start({bool immediate = true}) async {
    if (_closed || _timer != null) return;
    _timer = Timer.periodic(interval, (_) => _tick());
    if (immediate) await _tick();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Fire a single poll now without disturbing the schedule. Useful for
  /// pull-to-refresh or re-focus.
  Future<void> refreshNow() => _tick();

  Future<void> _tick() async {
    if (_closed || _running) return;
    _running = true;
    try {
      await task();
    } catch (e, st) {
      onError?.call(e, st);
    } finally {
      _running = false;
    }
  }

  void close() {
    _closed = true;
    stop();
  }
}
