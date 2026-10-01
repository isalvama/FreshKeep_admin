import 'dart:async';

/// Fired by [AuthInterceptor] when the backend rejects the session (401).
/// `AuthBloc` listens and logs out, so features never handle 401 themselves.
class SessionExpiredNotifier {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() => _controller.add(null);

  Future<void> dispose() => _controller.close();
}
