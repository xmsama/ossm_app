import 'package:flutter/material.dart';

import '../state/session_controller.dart';
import '../theme/palette.dart';
import '../widgets/pattern_picker.dart';
import '../widgets/speed_dial.dart';
import '../widgets/stroke_axis.dart';
import '../widgets/top_bar.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key, required this.session});
  final SessionController session;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListenableBuilder(
      listenable: session,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          TopBar(
            connected: session.connected,
            voltage: session.fresh ? session.voltage : null,
            tempC: session.fresh ? session.tempC : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: session.canControl
                        ? OssmPalette.cyan
                        : OssmPalette.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.status,
                    style: const TextStyle(
                      fontSize: 13,
                      color: OssmPalette.textMuted,
                    ),
                  ),
                ),
                if (session.remainingSeconds != null)
                  Text(
                    '${session.remainingSeconds! ~/ 60}:${(session.remainingSeconds! % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(color: OssmPalette.cyan),
                  ),
              ],
            ),
          ),
          Center(
            child: SizedBox(
              width: (MediaQuery.sizeOf(context).height - 640).clamp(
                168.0,
                256.0,
              ),
              height: (MediaQuery.sizeOf(context).height - 640).clamp(
                168.0,
                256.0,
              ),
              child: SpeedDial(
                speed: session.speed,
                running: session.running,
                onNudge: session.nudgeSpeed,
                onToggle: session.toggleRun,
              ),
            ),
          ),
          Center(
            child: Text(
              '旋转调节速度 · 上限 ${session.speedLimit.round()}%',
              style: const TextStyle(
                color: OssmPalette.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StrokeAxis(
              homed: session.homed,
              travelMm: session.travelMm,
              shallow: session.shallow,
              depth: session.depth,
              strokeMm: session.strokeMm,
              depthMm: session.depthMm,
              onShallow: session.setShallow,
              onDeep: session.setDeep,
              onShift: session.shiftDepth,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: FilledButton.icon(
              onPressed: session.running
                  ? session.stop
                  : session.canStart
                  ? session.toggleRun
                  : null,
              icon: Icon(
                session.running
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(
                session.running
                    ? '停止运行'
                    : session.busy
                    ? '等待设备确认…'
                    : '启动',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text('手感'),
                Expanded(
                  child: Slider(
                    value: session.sensation,
                    min: 0,
                    max: 100,
                    onChanged: session.canEdit ? session.setSensation : null,
                  ),
                ),
                Text(session.sensation.round().toString()),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '出程更快',
                  style: TextStyle(fontSize: 11, color: OssmPalette.textMuted),
                ),
                Text(
                  '50 中性',
                  style: TextStyle(fontSize: 11, color: OssmPalette.textMuted),
                ),
                Text(
                  '入程更快',
                  style: TextStyle(fontSize: 11, color: OssmPalette.textMuted),
                ),
              ],
            ),
          ),
          IgnorePointer(
            ignoring: !session.canEdit,
            child: Opacity(
              opacity: session.canEdit ? 1 : .45,
              child: PatternPicker(
                selected: session.patternIndex,
                onSelect: session.selectPattern,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Text(
              session.pattern.hint,
              style: const TextStyle(
                fontSize: 12,
                color: OssmPalette.textMuted,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
