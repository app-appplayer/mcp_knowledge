/// Event Bus - Event bus for knowledge system events.
library;

import 'dart:async';
import 'knowledge_event.dart';

/// Event bus for knowledge system.
class KnowledgeEventBus {
  /// Create a new event bus.
  KnowledgeEventBus()
      : _controller = StreamController<KnowledgeEvent>.broadcast();
  final StreamController<KnowledgeEvent> _controller;

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
  ///
  /// Subscriber exceptions are deliberately isolated from emitters and other
  /// subscribers: handler throws are swallowed here. The bus only ever adds
  /// events, never errors. Callers that need custom error handling should use
  /// [on] and wire their own `listen`.
  StreamSubscription<T> subscribe<T extends KnowledgeEvent>(
    void Function(T event) handler,
  ) {
    return on<T>().listen(
      (event) {
        try {
          handler(event);
        } catch (_) {
          // Subscriber exceptions are deliberately isolated from emitters.
        }
      },
    );
  }

  /// Close the event bus.
  Future<void> close() async {
    await _controller.close();
  }
}
