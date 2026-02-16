/// Event Bus - Event bus for knowledge system events.
library;

import 'dart:async';
import 'knowledge_event.dart';

/// Event bus for knowledge system.
class KnowledgeEventBus {
  final StreamController<KnowledgeEvent> _controller;

  /// Create a new event bus.
  KnowledgeEventBus()
      : _controller = StreamController<KnowledgeEvent>.broadcast();

  /// Emit an event.
  void emit(KnowledgeEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  /// Stream of all events.
  Stream<KnowledgeEvent> get stream => _controller.stream;

  /// Stream filtered by event type.
  Stream<T> on<T extends KnowledgeEvent>() {
    return _controller.stream.where((e) => e is T).cast<T>();
  }

  /// Subscribe with handler.
  StreamSubscription<T> subscribe<T extends KnowledgeEvent>(
    void Function(T) handler,
  ) {
    return on<T>().listen(handler);
  }

  /// Close the event bus.
  Future<void> close() async {
    await _controller.close();
  }
}
