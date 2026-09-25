import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/palette.dart';

enum _Handle { none, shallow, deep, band }

/// Vertical rail: 0 mm (homing end) at the top, full travel at the bottom.
/// The highlighted window is [shallow, depth] in percent of travel.
class StrokeRail extends StatefulWidget {
  const StrokeRail({
    super.key,
    required this.enabled,
    required this.homed,
    required this.running,
    required this.travelMm,
    required this.shallow,
    required this.depth,
    required this.positionMm,
    required this.onShallow,
    required this.onDeep,
    required this.onShift,
  });

  final bool enabled, homed, running;
  final double travelMm, shallow, depth;
  final double? positionMm;
  final ValueChanged<double> onShallow, onDeep, onShift;

  @override
  State<StrokeRail> createState() => _StrokeRailState();
}

class _StrokeRailState extends State<StrokeRail>
    with SingleTickerProviderStateMixin {
  static const _pad = 14.0;
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  _Handle _handle = _Handle.none;
  double _grab = 0;

  @override
  void initState() {
    super.initState();
    if (widget.running) _flow.repeat();
  }

  @override
  void didUpdateWidget(covariant StrokeRail old) {
    super.didUpdateWidget(old);
    if (widget.running && !_flow.isAnimating) _flow.repeat();
    if (!widget.running && _flow.isAnimating) _flow.stop();
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  double _value(double y, double h) =>
      ((y - _pad) / (h - _pad * 2)).clamp(0.0, 1.0) * 100;

  void _start(Offset p, double h) {
    if (!widget.enabled) return;
    final span = h - _pad * 2;
    final yLo = _pad + widget.shallow / 100 * span;
    final yHi = _pad + widget.depth / 100 * span;
    const slop = 26.0;
    final dLo = (p.dy - yLo).abs(), dHi = (p.dy - yHi).abs();
    if (dLo <= slop || dHi <= slop) {
      _handle = dLo < dHi ? _Handle.shallow : _Handle.deep;
    } else if (p.dy > yLo && p.dy < yHi) {
      _handle = _Handle.band;
      _grab = widget.shallow - _value(p.dy, h);
    } else {
      _handle = dLo < dHi ? _Handle.shallow : _Handle.deep;
    }
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _move(Offset p, double h) {
    final v = _value(p.dy, h);
    switch (_handle) {
      case _Handle.shallow:
        widget.onShallow(v);
      case _Handle.deep:
        widget.onDeep(v);
      case _Handle.band:
        widget.onShift(v + _grab - widget.shallow);
      case _Handle.none:
        break;
    }
  }

  void _end() => setState(() => _handle = _Handle.none);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _start(e.localPosition, box.maxHeight),
      onPointerMove: (e) => _move(e.localPosition, box.maxHeight),
      onPointerUp: (_) => _end(),
      onPointerCancel: (_) => _end(),
      child: TweenAnimationBuilder<double>(
        tween: Tween(
          end: widget.travelMm > 0 && widget.positionMm != null
              ? (widget.positionMm! / widget.travelMm).clamp(0.0, 1.0)
              : -1,
        ),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, pos, _) => AnimatedBuilder(
          animation: _flow,
          builder: (context, _) => CustomPaint(
            size: Size(box.maxWidth, box.maxHeight),
            painter: _RailPainter(
              shallow: widget.shallow,
              depth: widget.depth,
              travelMm: widget.travelMm,
              homed: widget.homed,
              enabled: widget.enabled,
              active: _handle,
              position: widget.running || widget.positionMm == null
                  ? null
                  : pos,
              flow: widget.running ? _flow.value : null,
            ),
          ),
        ),
      ),
    ),
  );
}

class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.shallow,
    required this.depth,
    required this.travelMm,
    required this.homed,
    required this.enabled,
    required this.active,
    required this.position,
    required this.flow,
  });

  final double shallow, depth, travelMm;
  final bool homed, enabled;
  final _Handle active;
  final double? position, flow;

  static const pad = 14.0;

  void _text(
    Canvas canvas,
    String s,
    Offset at, {
    Color color = OssmPalette.textMuted,
    double size = 12,
    FontWeight weight = FontWeight.w500,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: 'OssmSans',
          fontSize: size,
          fontWeight: weight,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(0, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final x = math.min(34.0, size.width * .28);
    final top = pad, bottom = size.height - pad, span = bottom - top;
    final yLo = top + shallow / 100 * span;
    final yHi = top + depth / 100 * span;
    final dim = enabled ? 1.0 : .45;
    final mm = travelMm > 0;

    // Scale ticks every 10 % of travel.
    final tick = Paint()
      ..color = OssmPalette.textDim.withValues(alpha: .45 * dim)
      ..strokeWidth = 1;
    for (var i = 0; i <= 10; i++) {
      final y = top + span * i / 10;
      final w = i % 5 == 0 ? 9.0 : 5.0;
      canvas.drawLine(Offset(x - 12 - w, y), Offset(x - 12, y), tick);
    }

    // Rail.
    canvas.drawRRect(
      RRect.fromLTRBR(x - 4, top, x + 4, bottom, const Radius.circular(4)),
      Paint()..color = OssmPalette.track.withValues(alpha: dim),
    );

    // Active window.
    final band = RRect.fromLTRBR(
      x - 6,
      yLo,
      x + 6,
      math.max(yHi, yLo + 1),
      const Radius.circular(6),
    );
    final bandRect = Rect.fromLTRB(0, yLo, size.width, yHi + 1);
    canvas.drawRRect(
      band.inflate(4),
      Paint()
        ..color = OssmPalette.magenta.withValues(
          alpha: (active == _Handle.none ? .16 : .32) * dim,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OssmPalette.cyan.withValues(alpha: dim),
            OssmPalette.violet.withValues(alpha: dim),
            OssmPalette.pink.withValues(alpha: dim),
          ],
        ).createShader(bandRect),
    );

    // Running: a soft light travelling through the window (illustrative).
    if (flow != null && yHi - yLo > 4) {
      final t = .5 - .5 * math.cos(flow! * math.pi * 2);
      final y = yLo + (yHi - yLo) * t;
      canvas.drawCircle(
        Offset(x, y),
        14,
        Paint()
          ..color = Colors.white.withValues(alpha: .35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }

    // Handles and their labels.
    final labelX = x + 22;
    _handle(canvas, Offset(x, yLo), active == _Handle.shallow, dim);
    _handle(canvas, Offset(x, yHi), active == _Handle.deep, dim);
    final loY = yHi - yLo < 34 ? yLo - (34 - (yHi - yLo)) / 2 : yLo;
    final hiY = yHi - yLo < 34 ? yHi + (34 - (yHi - yLo)) / 2 : yHi;
    String v(double pct) =>
        mm ? '${(pct / 100 * travelMm).round()}' : '${pct.round()}%';
    _text(canvas, '起点', Offset(labelX, loY - 8), size: 11,
        color: OssmPalette.textDim);
    _text(canvas, v(shallow), Offset(labelX + 28, loY - 8),
        size: 13, color: OssmPalette.text);
    _text(canvas, '最深', Offset(labelX, hiY + 8), size: 11,
        color: OssmPalette.textDim);
    _text(canvas, v(depth), Offset(labelX + 28, hiY + 8),
        size: 13, color: OssmPalette.text);

    // Rail ends.
    if (loY - 8 > top + 22) {
      _text(canvas, '0', Offset(labelX, top), size: 11,
          color: OssmPalette.textDim);
    }
    if (hiY + 8 < bottom - 22) {
      _text(
        canvas,
        mm ? '${travelMm.round()} mm' : '100%',
        Offset(labelX, bottom),
        size: 11,
        color: OssmPalette.textDim,
      );
    }

    // Live rod position (only meaningful while stopped).
    if (position != null && position! >= 0 && homed) {
      final y = top + position! * span;
      canvas.drawLine(
        Offset(x - 16, y),
        Offset(x + 12, y),
        Paint()
          ..color = OssmPalette.text.withValues(alpha: .9)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      final path = Path()
        ..moveTo(x - 18, y - 5)
        ..lineTo(x - 12, y)
        ..lineTo(x - 18, y + 5)
        ..close();
      canvas.drawPath(path, Paint()..color = OssmPalette.text);
    }
  }

  void _handle(Canvas canvas, Offset c, bool hot, double dim) {
    canvas.drawCircle(
      c,
      hot ? 17 : 13,
      Paint()
        ..color = OssmPalette.pink.withValues(alpha: (hot ? .4 : .22) * dim)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(c, hot ? 11 : 9.5, Paint()..color = const Color(0xFF1A1028));
    canvas.drawCircle(
      c,
      hot ? 11 : 9.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = OssmPalette.text.withValues(alpha: .92 * dim),
    );
  }

  @override
  bool shouldRepaint(covariant _RailPainter old) =>
      old.shallow != shallow ||
      old.depth != depth ||
      old.travelMm != travelMm ||
      old.homed != homed ||
      old.enabled != enabled ||
      old.active != active ||
      old.position != position ||
      old.flow != flow;
}
