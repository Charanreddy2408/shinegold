import 'dart:async';

import 'package:flutter/foundation.dart';

/// Debounces rapid callbacks (search typing, filter taps).
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 350)});

  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Prevents stale async responses from overwriting newer results.
class LoadGeneration {
  int _generation = 0;

  int next() => ++_generation;

  bool isCurrent(int generation) => generation == _generation;
}
