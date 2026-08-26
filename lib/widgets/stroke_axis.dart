import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/palette.dart';

enum _Handle { none, shallow, deep, band }

/// Measured rail (0 → travel) with a draggable [depth − stroke, depth] window.
class StrokeAxis extends StatefulWidget {
  const StrokeAxis({
    super.key,
    required this.homed,
    required this.travelMm,
    required this.shallow,
    required this.depth,
    required this.strokeMm,
    required this.depthMm,
    required this.onShallow,
    required this.onDeep,
    required this.onShift,
  });

  final bool homed;
  final double travelMm;
  final double shallow;
  final double depth;
  final double strokeMm;
  final double depthMm;
  final ValueChanged<double> onShallow;
  final ValueChanged<double> onDeep;
  final ValueChanged<double> onShift;

  @override
  State<StrokeAxis> createState() => _StrokeAxisState();
}

class _StrokeAxisState extends State<StrokeAxis> {
  _Handle _handle = _Handle.none;
  double? _grabOffset;
  static const _inset = 18.0;

  double _valueAt(double localX, double left, double width) {
    return ((localX - left) / width).clamp(0.0, 1.0) * 100;
  }

  void _start(Offset p, double left, double width) {
    final xLo = left + widget.shallow / 100 * width;
    final xHi = left + widget.depth / 100 * width;
    const slop = 22.0;
    if ((p.dx - xLo).abs() <= slop) {
      _handle = _Handle.shallow;
    } else if ((p.dx - xHi).abs() <= slop) {
      _handle = _Handle.deep;
    } else if (p.dx > xLo && p.dx < xHi) {
      _handle = _Handle.band;
      _grabOffset = widget.shallow - _valueAt(p.dx, left, width);
    } else {
      _handle = (p.dx - xLo).abs() < (p.dx - xHi).abs()
          ? _Handle.shallow
          : _Handle.deep;
    }
    HapticFeedback.selectionClick();
  }

  void _update(Offset p, double left, double width) {
    final v = _valueAt(p.dx, left, width);
    switch (_handle) {
      case _Handle.shallow:
        widget.onShallow(v);
      case _Handle.deep:
        widget.onDeep(v);
      case _Handle.band:
        final target = v + (_grabOffset ?? 0);
        widget.onShift(target - widget.shallow);
      case _Handle.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.homed
        ? '冲程 ${widget.strokeMm.round()} mm  ·  最深 ${widget.depthMm.round()} mm'
        : '未标定 · 回零后才有真实行程';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                widget.homed ? '0' : '—',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: OssmPalette.textDim,
                ),
              ),
              Expanded(
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: OssmPalette.textMuted,
                  ),
                ),
              ),
              Text(
                widget.homed ? '${widget.travelMm.round()} mm' : '—',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: OssmPalette.textDim,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: LayoutBuilder(
            builder: (context, box) {
              final left = _inset;
              final width = box.maxWidth - _inset * 2;
              return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _start(e.localPosition, left, width),
                onPointerMove: (e) => _update(e.localPosition, left, width),
                onPointerUp: (_) => _handle = _Handle.none,
                onPointerCancel: (_) => _handle = _Handle.none,
                child: CustomPaint(
                  size: Size(box.maxWidth, box.maxHeight),
                  painter: _RailPainter(
                    shallow: widget.shallow,
                    depth: widget.depth,
                    active: _handle != _Handle.none,
                    homed: widget.homed,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.shallow,
    required this.depth,
    required this.active,
    required this.homed,
  });

  final double shallow;
  final double depth;
  final bool active;
  final bool homed;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 18.0;
    final cy = size.height / 2;
    final left = inset;
    final right = size.width - inset;
    final w = right - left;
    final xLo = left + shallow / 100 * w;
    final xHi = left + depth / 100 * w;

    // Full measured rail.
    canvas.drawRRect(
      RRect.fromLTRBR(left, cy - 3, right, cy + 3, const Radius.circular(8)),
      Paint()..color = OssmPalette.track,
    );

    // End ticks.
    final tick = Paint()
      ..color = OssmPalette.textDim
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(left, cy - 8), Offset(left, cy + 8), tick);
    canvas.drawLine(Offset(right, cy - 8), Offset(right, cy + 8), tick);

    // Active window.
    final fill = RRect.fromLTRBR(
      xLo,
      cy - (active ? 5 : 4),
      xHi,
      cy + (active ? 5 : 4),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      fill,
      Paint()
        ..shader = const LinearGradient(
          colors: [OssmPalette.pink, OssmPalette.violet, OssmPalette.cyan],
        ).createShader(Rect.fromLTRB(xLo, 0, xHi, size.height)),
    );

    if (active) {
      canvas.drawRRect(
        fill.inflate(5),
        Paint()
          ..color = OssmPalette.magenta.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    _thumb(canvas, Offset(xLo, cy));
    _thumb(canvas, Offset(xHi, cy));
  }

  void _thumb(Canvas canvas, Offset c) {
    canvas.drawCircle(
      c,
      12,
      Paint()
        ..color = OssmPalette.pink.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawCircle(c, 9, Paint()..color = const Color(0xFF1A1028));
    canvas.drawCircle(
      c,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..shader = const SweepGradient(
          colors: [OssmPalette.pink, OssmPalette.violet, OssmPalette.cyan],
        ).createShader(Rect.fromCircle(center: c, radius: 9)),
    );
  }

  @override
  bool shouldRepaint(covariant _RailPainter old) =>
      old.shallow != shallow ||
      old.depth != depth ||
      old.active != active ||
      old.homed != homed;
}
