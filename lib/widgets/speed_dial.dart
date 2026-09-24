import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/palette.dart';

/// Full-circle gradient dial. Twist to change speed, tap (no twist) to run/stop.
class SpeedDial extends StatefulWidget {
  const SpeedDial({
    super.key,
    required this.speed,
    required this.running,
    required this.onNudge,
    required this.onToggle,
  });

  final double speed;
  final bool running;
  final ValueChanged<double> onNudge;
  final VoidCallback onToggle;

  @override
  State<SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<SpeedDial>
    with SingleTickerProviderStateMixin {
  static const _turnsForFull = 1.35;
  static const _tapAngle = 0.11;
  static const _tapPixels = 14.0;

  late final AnimationController _pulse;
  int? _pointer;
  double? _lastAngle;
  double _travelAngle = 0;
  double _travelPixels = 0;
  bool _hitEdge = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.running) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SpeedDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.running && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  double _angle(Offset p, Offset c) => math.atan2(p.dy - c.dy, p.dx - c.dx);

  double _wrap(double d) {
    while (d > math.pi) {
      d -= math.pi * 2;
    }
    while (d < -math.pi) {
      d += math.pi * 2;
    }
    return d;
  }

  void _down(PointerDownEvent e, Offset center) {
    _pointer = e.pointer;
    _lastAngle = _angle(e.localPosition, center);
    _travelAngle = 0;
    _travelPixels = 0;
    _hitEdge = widget.speed <= 0 || widget.speed >= 100;
  }

  void _move(PointerMoveEvent e, Offset center) {
    if (_pointer != e.pointer || _lastAngle == null) return;
    final angle = _angle(e.localPosition, center);
    final delta = _wrap(angle - _lastAngle!);
    _lastAngle = angle;
    _travelAngle += delta.abs();
    _travelPixels += e.localDelta.distance;

    final next = (widget.speed + delta / (_turnsForFull * math.pi * 2) * 100)
        .clamp(0.0, 100.0);
    final atEdge = next <= 0 || next >= 100;
    if (atEdge && !_hitEdge) {
      HapticFeedback.selectionClick();
    }
    _hitEdge = atEdge;
    widget.onNudge(delta / (_turnsForFull * math.pi * 2) * 100);
  }

  void _up(PointerUpEvent e) {
    if (_pointer != e.pointer) return;
    final isTap = _travelAngle < _tapAngle && _travelPixels < _tapPixels;
    _pointer = null;
    _lastAngle = null;
    if (isTap) {
      HapticFeedback.lightImpact();
      widget.onToggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final side = math.min(box.maxWidth, box.maxHeight);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) => _down(e, Offset(side / 2, side / 2)),
                  onPointerMove: (e) => _move(e, Offset(side / 2, side / 2)),
                  onPointerUp: _up,
                  onPointerCancel: (_) {
                    _pointer = null;
                    _lastAngle = null;
                  },
                  child: CustomPaint(
                    painter: _DialPainter(
                      speed: widget.speed,
                      running: widget.running,
                      pulse: _pulse.value,
                    ),
                    child: Center(
                      child: _DialReadout(
                        speed: widget.speed,
                        running: widget.running,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DialReadout extends StatelessWidget {
  const _DialReadout({required this.speed, required this.running});

  final double speed;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '速  度',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 4,
            color: running
                ? OssmPalette.magenta.withValues(alpha: 0.85)
                : OssmPalette.textDim,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${speed.round()}',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 76,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          '%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 13,
            letterSpacing: 2,
            color: OssmPalette.textMuted,
          ),
        ),
      ],
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.speed,
    required this.running,
    required this.pulse,
  });

  final double speed;
  final bool running;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 22;
    final rect = Rect.fromCircle(center: c, radius: r);
    final sweep = SweepGradient(
      startAngle: -math.pi / 2,
      colors: OssmPalette.ring,
    ).createShader(rect);

    final glow = (0.18 + speed / 100 * 0.42 + (running ? pulse * 0.18 : 0))
        .clamp(0.12, 0.85);
    final glowSigma = 14.0 + speed / 100 * 10 + (running ? pulse * 6 : 0);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..shader = sweep
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma)
        ..color = Colors.white.withValues(alpha: glow),
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..color = OssmPalette.track,
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..shader = sweep,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.speed != speed || old.running != running || old.pulse != pulse;
}
