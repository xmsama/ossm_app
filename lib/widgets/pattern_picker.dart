import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stroke_pattern.dart';
import '../theme/palette.dart';

class PatternPicker extends StatelessWidget {
  const PatternPicker({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          color: OssmPalette.surface.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          scrollDirection: Axis.horizontal,
          itemCount: StrokePattern.catalog.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final pattern = StrokePattern.catalog[i];
            final on = i == selected;
            return _Card(
              pattern: pattern,
              selected: on,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(i);
              },
            );
          },
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.pattern,
    required this.selected,
    required this.onTap,
  });

  final StrokePattern pattern;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 86,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? OssmPalette.surfaceHi
              : OssmPalette.surface.withValues(alpha: 0.85),
          border: Border.all(
            color: selected
                ? OssmPalette.magenta.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.06),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: OssmPalette.magenta.withValues(alpha: 0.28),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ]
              : const [],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Column(
            children: [
              Expanded(
                child: pattern.isCustom
                    ? const Center(
                        child: Icon(
                          Icons.edit_rounded,
                          color: OssmPalette.textMuted,
                          size: 22,
                        ),
                      )
                    : CustomPaint(
                        painter: _WavePainter(pattern: pattern, lit: selected),
                        child: const SizedBox.expand(),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                pattern.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? OssmPalette.text : OssmPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.pattern, required this.lit});

  final StrokePattern pattern;
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const samples = 48;
    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      final x = t * size.width;
      final y = pattern.sample(t) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final shader = LinearGradient(
      colors: lit
          ? const [OssmPalette.pink, OssmPalette.violet, OssmPalette.cyan]
          : [OssmPalette.textDim, OssmPalette.textMuted.withValues(alpha: 0.7)],
    ).createShader(Offset.zero & size);

    if (lit) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
          ..color = Colors.white.withValues(alpha: 0.55),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.pattern.id != pattern.id || old.lit != lit;
}
