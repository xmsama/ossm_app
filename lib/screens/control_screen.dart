import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/session_controller.dart';
import '../theme/palette.dart';
import '../widgets/panel.dart';
import '../widgets/pattern_picker.dart';
import '../widgets/sensation_control.dart';
import '../widgets/speed_fader.dart';
import '../widgets/stroke_rail.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key, required this.session});
  final SessionController session;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListenableBuilder(
      listenable: session,
      builder: (context, _) => LayoutBuilder(
        // One screen on normal phones; scrolls instead of squashing on tiny ones.
        builder: (context, box) => SingleChildScrollView(
          child: SizedBox(
            height: math.max(box.maxHeight, 540),
            child: Column(
              children: [
                _Header(session: session),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 11, child: _StrokePanel(session: session)),
                        const SizedBox(width: 10),
                        Expanded(flex: 9, child: _SpeedPanel(session: session)),
                      ],
                    ),
                  ),
                ),
                PatternPicker(
                  selected: session.patternIndex,
                  enabled: session.canEdit,
                  onSelect: session.selectPattern,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: SensationControl(
                    pattern: session.pattern,
                    value: session.sensation,
                    enabled: session.canEdit,
                    onChanged: session.setSensation,
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

class _Header extends StatelessWidget {
  const _Header({required this.session});
  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final remaining = s.remainingSeconds;
    const meta = TextStyle(
      fontSize: 12,
      color: OssmPalette.textMuted,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StateChip(label: s.stateLabel, tone: s.tone),
              if (s.demo) ...[
                const SizedBox(width: 8),
                const _Badge('演示'),
              ],
              const Spacer(),
              if (remaining != null) ...[
                const Icon(Icons.timer_outlined, size: 15, color: OssmPalette.cyan),
                const SizedBox(width: 4),
                Text(
                  '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                  style: meta.copyWith(color: OssmPalette.cyan, fontSize: 13),
                ),
                const SizedBox(width: 12),
              ],
              if (s.fresh) ...[
                Text('${s.voltage.toStringAsFixed(1)} V', style: meta),
                const SizedBox(width: 10),
                Text(
                  '${s.tempC.toStringAsFixed(0)} °C',
                  style: meta.copyWith(
                    color: s.tempC >= 70 ? OssmPalette.warning : null,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (s.connected) s.transport.name,
              if (s.status != s.stateLabel && s.status != '已就绪') s.status,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: OssmPalette.textDim),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: OssmPalette.warning.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, color: OssmPalette.warning),
    ),
  );
}

class _StrokePanel extends StatelessWidget {
  const _StrokePanel({required this.session});
  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final mm = s.travelMm > 0;
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PanelLabel('行程'),
          const SizedBox(height: 2),
          _BigValue(
            value: mm ? s.strokeMm.round().toString() : s.stroke.round().toString(),
            unit: mm ? 'mm' : '%',
          ),
          Expanded(
            child: StrokeRail(
              enabled: s.canEdit,
              homed: s.homed,
              running: s.running && !s.stopping,
              travelMm: s.travelMm,
              shallow: s.shallow,
              depth: s.depth,
              positionMm: s.fresh ? s.positionMm : null,
              onShallow: s.setShallow,
              onDeep: s.setDeep,
              onShift: s.shiftDepth,
            ),
          ),
          Text(
            s.homed ? '拖动端点调整 · 拖动中段整体移动' : '未回零 · 位置仅供参考',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, color: OssmPalette.textDim),
          ),
        ],
      ),
    );
  }
}

class _SpeedPanel extends StatelessWidget {
  const _SpeedPanel({required this.session});
  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final s = session;
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelLabel(
            '速度',
            trailing: Text(
              '上限 ${s.speedLimit.round()}',
              style: const TextStyle(fontSize: 11, color: OssmPalette.textDim),
            ),
          ),
          const SizedBox(height: 2),
          _BigValue(value: s.speed.round().toString(), unit: '%'),
          Expanded(
            child: SpeedFader(
              speed: s.speed,
              limit: s.speedLimit,
              running: s.running && !s.stopping,
              enabled: s.canEdit,
              onChanged: s.setSpeed,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Step(
                icon: Icons.remove_rounded,
                label: '减速',
                onTap: s.canEdit && s.speed > 0 ? () => s.nudgeSpeed(-5) : null,
              ),
              _Step(
                icon: Icons.add_rounded,
                label: '加速',
                onTap: s.canEdit && s.speed < s.speedLimit
                    ? () => s.nudgeSpeed(5)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigValue extends StatelessWidget {
  const _BigValue({required this.value, required this.unit});
  final String value, unit;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 34,
          height: 1.15,
          fontWeight: FontWeight.w500,
          color: OssmPalette.text,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(width: 4),
      Text(
        unit,
        style: const TextStyle(fontSize: 13, color: OssmPalette.textMuted),
      ),
    ],
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 40,
    child: IconButton(
      tooltip: label,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: OssmPalette.surfaceHi,
        disabledBackgroundColor: OssmPalette.surfaceHi.withValues(alpha: .4),
        foregroundColor: OssmPalette.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 20),
    ),
  );
}
