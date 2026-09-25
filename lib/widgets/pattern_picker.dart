import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stroke_pattern.dart';
import '../theme/palette.dart';

class PatternPicker extends StatelessWidget {
  const PatternPicker({
    super.key,
    required this.selected,
    required this.onSelect,
    this.enabled = true,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 74,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: StrokePattern.catalog.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) => _Tile(
        pattern: StrokePattern.catalog[i],
        selected: i == selected,
        enabled: enabled,
        onTap: () {
          if (!enabled || i == selected) return;
          HapticFeedback.selectionClick();
          onSelect(i);
        },
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.pattern,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final StrokePattern pattern;
  final bool selected, enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: pattern.name,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? OssmPalette.surfaceHi
              : OssmPalette.surface.withValues(alpha: .7),
          border: Border.all(
            color: selected
                ? OssmPalette.magenta.withValues(alpha: .8)
                : Colors.white.withValues(alpha: .05),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Opacity(
          opacity: enabled || selected ? 1 : .5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 7),
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: PatternWavePainter(pattern: pattern, lit: selected),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pattern.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? OssmPalette.text : OssmPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PatternWavePainter extends CustomPainter {
  PatternWavePainter({required this.pattern, required this.lit});

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
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final shader = LinearGradient(
      colors: lit
          ? const [OssmPalette.pink, OssmPalette.violet, OssmPalette.cyan]
          : [OssmPalette.textDim, OssmPalette.textMuted.withValues(alpha: .7)],
    ).createShader(Offset.zero & size);
    if (lit) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant PatternWavePainter old) =>
      old.pattern.id != pattern.id || old.lit != lit;
}
