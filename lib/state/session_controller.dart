import 'package:flutter/foundation.dart';

import '../models/stroke_pattern.dart';

/// In-memory session. BLE / homing come later; UI talks only to this.
///
/// Depth and stroke are % of the *measured* travel (homing), matching
/// StrokeEngine: motion lives in `[depth - stroke, depth]`.
class SessionController extends ChangeNotifier {
  static const minSpan = 8.0;
  static const maxHz = 6.0;

  /// Mock: pretend the machine already homed. Real mm only exist after this.
  bool homed = true;
  double travelMm = 150;

  double speed = 36;

  /// Deep end, 0–100 of measured travel.
  double depth = 78;

  /// Amplitude, 0–100 of measured travel. Always ≤ depth.
  double stroke = 45;

  bool running = false;
  int patternIndex = 0;

  bool connected = true;
  double voltage = 24.1;
  double tempC = 32;
  int battery = 87;

  StrokePattern get pattern => StrokePattern.catalog[patternIndex];

  double get hz => speed / 100 * maxHz;

  double get shallow => (depth - stroke).clamp(0.0, 100.0);

  double get depthMm => depth / 100 * travelMm;
  double get strokeMm => stroke / 100 * travelMm;
  double get shallowMm => shallow / 100 * travelMm;

  void nudgeSpeed(double delta) {
    final next = (speed + delta).clamp(0.0, 100.0);
    if (next == speed) return;
    speed = next;
    notifyListeners();
  }

  void toggleRun() {
    running = !running;
    notifyListeners();
  }

  void selectPattern(int index) {
    if (index < 0 || index >= StrokePattern.catalog.length) return;
    if (index == patternIndex) return;
    patternIndex = index;
    notifyListeners();
  }

  /// Left handle: keep depth, change amplitude.
  void setShallow(double value) {
    final next = (depth - value).clamp(minSpan, depth);
    if (next == stroke) return;
    stroke = next;
    notifyListeners();
  }

  /// Right handle: keep shallow, move the deep end.
  void setDeep(double value) {
    final sh = shallow;
    final nextDepth = value.clamp(sh + minSpan, 100.0);
    final nextStroke = nextDepth - sh;
    if (nextDepth == depth && nextStroke == stroke) return;
    depth = nextDepth;
    stroke = nextStroke;
    notifyListeners();
  }

  /// Drag the window: translate, keep amplitude.
  void shiftDepth(double delta) {
    var next = depth + delta;
    if (next > 100) next = 100;
    if (next - stroke < 0) next = stroke;
    if (next == depth) return;
    depth = next;
    notifyListeners();
  }
}
