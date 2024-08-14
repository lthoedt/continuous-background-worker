import 'dart:async';
import 'package:flutter/foundation.dart';

class StreamProcessor<T> {
  late final StreamController<T> _controller;
  final ValueNotifier<int> length = ValueNotifier(0);

  StreamProcessor() {
    _controller = StreamController<T>();
  }

  void add(T event) {
    _controller.add(event);
    length.value++;
  }

  /// Calls the handler function for each emitted item.
  ///
  /// This method will hang until the stream is closed or an error occurred.
  Future<void> process(Future<void> Function(T) handler) async {
    if (_controller.hasListener) return;

    await for (final item in _controller.stream) {
      await handler(item);
      // This means the length is contains itself in the handler function.
      length.value--;
    }
  }
}
