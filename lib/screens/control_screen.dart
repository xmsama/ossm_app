import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/session_controller.dart';
import '../widgets/pattern_picker.dart';
import '../widgets/run_pill.dart';
import '../widgets/speed_dial.dart';
import '../widgets/stroke_axis.dart';
import '../widgets/top_bar.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          return Column(
            children: [
              TopBar(
                connected: session.connected,
                voltage: session.voltage,
                tempC: session.tempC,
                battery: session.battery,
              ),
              Expanded(child: _ControlCluster(session: session)),
              PatternPicker(
                selected: session.patternIndex,
                onSelect: session.selectPattern,
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

/// Dial, stroke bar and run pill as one vertical stack — same width, no orphaned circle.
class _ControlCluster extends StatelessWidget {
  const _ControlCluster({required this.session});

  final SessionController session;

  static const _maxDial = 280.0;
  static const _belowDial = 132.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final dial = math
            .min(box.maxWidth - 48, box.maxHeight - _belowDial - 8)
            .clamp(168.0, _maxDial);

        return Column(
          children: [
            const Spacer(flex: 2),
            SizedBox(
              width: dial,
              height: dial,
              child: SpeedDial(
                speed: session.speed,
                running: session.running,
                onNudge: session.nudgeSpeed,
                onToggle: session.toggleRun,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: dial + 24,
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
            const SizedBox(height: 16),
            RunPill(
              running: session.running,
              onToggle: session.toggleRun,
            ),
            const Spacer(flex: 3),
          ],
        );
      },
    );
  }
}
