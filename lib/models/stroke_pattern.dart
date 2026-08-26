import 'dart:math' as math;

enum PatternId { simple, stopGo, deeper, half, thrust, pulse, custom }

class StrokePattern {
  const StrokePattern({
    required this.id,
    required this.name,
    required this.hint,
  });

  final PatternId id;
  final String name;
  final String hint;

  bool get isCustom => id == PatternId.custom;

  /// Card thumbnail: [t] 0..1 covers the pattern's signature (2–4 cycles).
  /// 0 = deep (drawn toward top), 1 = shallow.
  double sample(double t) {
    return switch (id) {
      PatternId.simple => _simple(t),
      PatternId.stopGo => _stopGo(t),
      PatternId.deeper => _deeper(t),
      PatternId.half => _half(t),
      PatternId.thrust => _thrust(t),
      PatternId.pulse => _pulse(t),
      PatternId.custom => 0.5,
    };
  }

  /// Live monitor: [cycles] is continuous stroke count (0, 1.5, 8...).
  double live(double cycles) {
    return switch (id) {
      PatternId.simple => 0.5 + 0.36 * math.sin(cycles * math.pi * 2),
      PatternId.stopGo => _stopGoUnit(cycles % 1),
      PatternId.deeper => _deeperLive(cycles),
      PatternId.half => _halfLive(cycles),
      PatternId.thrust => _thrustUnit(cycles % 1),
      PatternId.pulse => _pulseUnit(cycles % 1),
      PatternId.custom => 0.5,
    };
  }

  static const catalog = <StrokePattern>[
    StrokePattern(id: PatternId.simple, name: '匀速', hint: '圆滑往复'),
    StrokePattern(id: PatternId.stopGo, name: '停顿', hint: '到底停一下'),
    StrokePattern(id: PatternId.deeper, name: '渐深', hint: '一圈比一圈深'),
    StrokePattern(id: PatternId.half, name: '交错', hint: '一深一浅'),
    StrokePattern(id: PatternId.thrust, name: '急推', hint: '进快出慢'),
    StrokePattern(id: PatternId.pulse, name: '脉冲', hint: '短促点刺'),
    StrokePattern(id: PatternId.custom, name: '自定义', hint: '自己画波形'),
  ];
}

double _smooth(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _simple(double t) => 0.5 + 0.36 * math.sin(t * 3 * math.pi * 2);

double _stopGo(double t) {
  final p = (t * 3) % 1;
  if (p < 0.16) return 0.18;
  if (p < 0.48) return 0.18 + 0.64 * _smooth((p - 0.16) / 0.32);
  if (p < 0.68) return 0.82;
  return 0.82 - 0.64 * _smooth((p - 0.68) / 0.32);
}

double _deeper(double t) {
  final cycle = t * 3;
  final n = cycle.floor().clamp(0, 2);
  final local = cycle - cycle.floor();
  final amp = 0.16 + n * 0.14;
  final y = 0.5 - 0.5 * math.cos(local * math.pi * 2);
  return 0.78 - amp * y;
}

double _half(double t) {
  final cycle = t * 4;
  final n = cycle.floor();
  final local = cycle - n;
  final amp = n.isEven ? 0.36 : 0.16;
  return 0.5 + amp * math.sin(local * math.pi * 2);
}

double _thrust(double t) {
  final p = (t * 3) % 1;
  if (p < 0.26) return 0.18 + 0.64 * _smooth(p / 0.26);
  return 0.82 - 0.64 * _smooth((p - 0.26) / 0.74);
}

double _pulse(double t) {
  final p = (t * 4) % 1;
  return _pulseUnit(p);
}

double _stopGoUnit(double p) {
  if (p < 0.16) return 0.18;
  if (p < 0.48) return 0.18 + 0.64 * _smooth((p - 0.16) / 0.32);
  if (p < 0.68) return 0.82;
  return 0.82 - 0.64 * _smooth((p - 0.68) / 0.32);
}

double _thrustUnit(double p) {
  if (p < 0.26) return 0.18 + 0.64 * _smooth(p / 0.26);
  return 0.82 - 0.64 * _smooth((p - 0.26) / 0.74);
}

double _pulseUnit(double p) {
  if (p < 0.2) return 0.22 + 0.56 * math.sin(p / 0.2 * math.pi);
  return 0.22;
}

double _deeperLive(double cycles) {
  final n = cycles.floor() % 3;
  final local = cycles - cycles.floor();
  final amp = 0.16 + n * 0.14;
  final y = 0.5 - 0.5 * math.cos(local * math.pi * 2);
  return 0.78 - amp * y;
}

double _halfLive(double cycles) {
  final n = cycles.floor();
  final local = cycles - n;
  final amp = n.isEven ? 0.36 : 0.16;
  return 0.5 + amp * math.sin(local * math.pi * 2);
}
