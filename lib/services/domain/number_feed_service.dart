import 'dart:async';

class NumberFeedService {
  static final List<NumberFeedService> _activeServices = [];
  final List<int> numbers;
  final Duration interval;
  late StreamController<int> _controller;

  NumberFeedService({
    required this.numbers,
    this.interval = const Duration(seconds: 1),
  }) {
    _activeServices.add(this);
    _controller = StreamController<int>(onListen: _startFeeding);
  }

  Stream<int> get numberStream => _controller.stream;

  /// Detiene y cierra todos los servicios activos.
  static void clearAll() {
    for (final service in _activeServices) {
      service.dispose();
    }
    _activeServices.clear();
  }

  void _startFeeding() async {
    for (final number in numbers) {
      await Future.delayed(interval);
      if (!_controller.isClosed) {
        _controller.add(number);
      }
    }
    _controller.close();
  }

  void dispose() {
    _controller.close();
  }
}
