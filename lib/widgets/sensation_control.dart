import 'package:flutter/material.dart';

import '../models/stroke_pattern.dart';
import '../theme/palette.dart';

/// Bipolar sensation slider whose meaning follows the selected pattern.
class SensationControl extends StatelessWidget {
  const SensationControl({
    super.key,
    required this.pattern,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final StrokePattern pattern;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final spec = pattern.sensation;
    final live = enabled && spec.enabled;
    const small = TextStyle(fontSize: 11, color: OssmPalette.textDim);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              spec.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: OssmPalette.text,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pattern.hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: small,
              ),
            ),
            if (spec.enabled)
              Text(
                pattern.readout(value),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: OssmPalette.magenta,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
        SizedBox(
          height: 34,
          child: spec.enabled
              ? SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackShape: const _CenteredTrack(),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9,
                    ),
                  ),
                  child: Slider(
                    value: value.clamp(0, 100),
                    min: 0,
                    max: 100,
                    onChanged: live ? onChanged : null,
                  ),
                )
              : Center(child: Text(spec.mid, style: small)),
        ),
        if (spec.enabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(child: Text(spec.low, style: small)),
                Text(spec.mid, style: small),
                Expanded(
                  child: Text(spec.high, textAlign: TextAlign.end, style: small),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Track filled from the centre toward the thumb.
class _CenteredTrack extends SliderTrackShape with BaseSliderTrackShape {
  const _CenteredTrack();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final canvas = context.canvas;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = OssmPalette.track,
    );
    final cx = rect.center.dx;
    final a = thumbCenter.dx < cx ? thumbCenter.dx : cx;
    final b = thumbCenter.dx < cx ? cx : thumbCenter.dx;
    canvas.drawRRect(
      RRect.fromLTRBR(a, rect.top, b, rect.bottom, const Radius.circular(4)),
      Paint()
        ..color = isEnabled
            ? OssmPalette.magenta
            : OssmPalette.magenta.withValues(alpha: .35),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, rect.center.dy), width: 2, height: 12),
      Paint()..color = OssmPalette.textDim,
    );
  }
}
