import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:async/async.dart';
import 'package:continuous_background_worker/src/stream_processor.dart';

import 'package:flutter_background_service/flutter_background_service.dart';

// This worker runs in the background and handles items from the queue.
mixin ContinuousBackgroundWorker<T> {
  final queue = StreamProcessor<T>();

  /// **Must** be called in order to start the background worker.
  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: false,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onStart,
      ),
    );
  }

  /// Starting point of the background worker.
  @pragma('vm:entry-point')
  Future<void> _onStart(ServiceInstance service) async {
    await _work(service);
  }

  /// Listens to the queue.
  ///
  /// @protected
  Future<void> handleQueue_() async {
    print("Starting queue processor");

    await queue.process((item) async {
      print("Handling item...");
      await handleItem_(item);
      print("Handled item.");
    });
  }

  /// This is the main worker loop.
  Future<void> _work(ServiceInstance service) async {
    late RestartableTimer timer;

    // This is a watchdog timer that checks if the worker is still alive.
    Timer.periodic(Duration(minutes: 1), (t) {
      if (!timer.isActive) {
        timer.reset();
        print("Worker died, reviving...");
      }
    });

    // This is the main timer that checks the queue.
    timer = RestartableTimer(
      const Duration(seconds: 30),
      () async {
        try {
          // This handleQueue_ will never exit unless it gets an error.
          await handleQueue_();
        } catch (e) {
          print("Error: $e");
        }
        timer.reset();
      },
    );
  }

  /// This is the method that will be called by the background worker.
  ///
  /// @protected
  Future<void> handleItem_(T item);

  /// @protected
  void addToQueue_(T item) => queue.add(item);

  ValueNotifier<int> get queueLength => queue.length;
}
