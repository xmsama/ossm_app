import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/palette.dart';

/// Vertical speed fader. Drag is relative (touching never jumps the value);
/// the zone above [limit] is locked by the App speed limit.
class SpeedFader extends StatefulWidget {
  const SpeedFader({
    super.key,
    required this.speed,
    required this.limit,
    required this.running,
    required this.enabled,
    required this.onChanged,
  });

  final double speed, limit;
  final bool running, enabled;
  final ValueChanged<double> onChanged;

  @override
  State<SpeedFader> createState() => _SpeedFaderState();
}

class _SpeedFaderState extends State<SpeedFader>
    with SingleTickerProviderStateMixin {
  static const _pad = 6.0;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  double? _startY, _startSpeed;
  int _lastStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.running) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SpeedFader old) {
    super.didUpdateWidget(old);
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

  void _down(PointerDownEvent e) {
    if (!widget.enabled) return;
    _startY = e.localPosition.dy;
    _startSpeed = widget.speed;
    _lastStep = widget.speed ~/ 10;
    setState(() {});
  }

  void _move(PointerMoveEvent e, double h) {
    if (_startY == null) return;
    final next = (_startSpeed! + (_startY! - e.localPosition.dy) / (h - _pad * 2) * 100)
        .clamp(0.0, widget.limit);
    final step = next ~/ 10;
    if (step != _lastStep || (next >= widget.limit && widget.speed < widget.limit)) {
      HapticFeedback.selectionClick();
    }
    _lastStep = step;
    widget.onChanged(next);
  }

  void _up() => setState(() => _startY = null);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: (e) => _move(e, box.maxHeight),
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.speed),
        duration: const Duration(milliseconds: 120),
        builder: (context, speed, _) => AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => CustomPaint(
            size: Size(box.maxWidth, box.maxHeight),
            painter: _FaderPainter(
              speed: speed,
              limit: widget.limit,
              enabled: widget.enabled,
              dragging: _startY != null,
              pulse: widget.running ? _pulse.value : 0,
            ),
          ),
        ),
      ),
    ),
  );
}

class _FaderPainter extends CustomPainter {
  _FaderPainter({
    required this.speed,
    required this.limit,
    required this.enabled,
    required this.dragging,
    required this.pulse,
  });
  final double speed, limit, pulse;
  final bool enabled, dragging;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = _SpeedFaderState._pad;
    final w = math.min(64.0, size.width * .62);
    final left = (size.width - w) / 2;
    final track = RRect.fromLTRBR(
      left,
      pad,
      left + w,
      size.height - pad,
      Radius.circular(w / 2.6),
    );
    final span = size.height - pad * 2;
    double yOf(double v) => size.height - pad - v / 100 * span;
    final dim = enabled ? 1.0 : .45;

    canvas.drawRRect(
      track,
      Paint()..color = OssmPalette.bgMid,
    );

    canvas.save();
    canvas.clipRRect(track);

    // Locked zone above the App limit.
    if (limit < 100) {
      final yL = yOf(limit);
      canvas.drawRect(
        Rect.fromLTRB(left, pad, left + w, yL),
        Paint()..color = OssmPalette.bg.withValues(alpha: .55),
      );
      final hatch = Paint()
        ..color = OssmPalette.track.withValues(alpha: .9)
        ..strokeWidth = 1.2;
      for (var d = -w; d < yL; d += 9) {
        canvas.drawLine(Offset(left, pad + d + w), Offset(left + w, pad + d), hatch);
      }
      canvas.drawRect(
        Rect.fromLTRB(left, yL, left + w, size.height),
        Paint()..color = OssmPalette.bgMid,
      );
      canvas.drawLine(
        Offset(left, yL),
        Offset(left + w, yL),
        Paint()
          ..color = OssmPalette.warning.withValues(alpha: .7)
          ..strokeWidth = 1.4,
      );
    }

    // Fill.
    final yS = yOf(speed);
    if (speed > 0) {
      final fill = Rect.fromLTRB(left, yS, left + w, size.height);
      canvas.drawRect(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              OssmPalette.cyan.withValues(alpha: .85 * dim),
              OssmPalette.violet.withValues(alpha: dim),
              OssmPalette.pink.withValues(alpha: dim),
            ],
          ).createShader(fill),
      );
      // Pulse sheen while running.
      if (pulse > 0) {
        canvas.drawRect(
          fill,
          Paint()..color = Colors.white.withValues(alpha: .10 * pulse),
        );
      }
    }
    canvas.restore();

    // Grip line at the fill edge.
    canvas.drawRRect(
      RRect.fromLTRBR(
        left + w * .22,
        yS - (dragging ? 3 : 2),
        left + w * .78,
        yS + (dragging ? 3 : 2),
        const Radius.circular(3),
      ),
      Paint()..color = OssmPalette.text.withValues(alpha: .95 * dim),
    );

    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: dragging ? .22 : .08),
    );

    // Side ticks.
    final tick = Paint()
      ..color = OssmPalette.textDim.withValues(alpha: .5 * dim)
      ..strokeWidth = 1;
    for (var i = 0; i <= 10; i++) {
      final y = yOf(i * 10.0);
      final l = i % 5 == 0 ? 8.0 : 4.0;
      canvas.drawLine(Offset(left - 6 - l, y), Offset(left - 6, y), tick);
    }

    // Limit tag.
    if (limit < 100) {
      final tp = TextPainter(
        text: TextSpan(
          text: '上限',
          style: TextStyle(
            fontFamily: 'OssmSans',
            fontSize: 10,
            color: OssmPalette.warning.withValues(alpha: .85),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left + w + 6, yOf(limit) - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _FaderPainter old) =>
      old.speed != speed ||
      old.limit != limit ||
      old.enabled != enabled ||
      old.dragging != dragging ||
      old.pulse != pulse;
}
