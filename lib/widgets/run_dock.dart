import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/session_controller.dart';
import '../theme/palette.dart';

/// Always-visible action row: context-aware run button + emergency stop.
class RunDock extends StatelessWidget {
  const RunDock({super.key, required this.session, required this.onOpenDevice});
  final SessionController session;
  final VoidCallback onOpenDevice;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final (String label, IconData icon, VoidCallback? action, bool hot) =
        switch (s) {
          _ when !s.connected => ('连接设备', Icons.bluetooth_searching_rounded, onOpenDevice, false),
          _ when s.faulted => ('查看故障', Icons.error_outline_rounded, onOpenDevice, false),
          _ when s.homing => ('停止回零', Icons.stop_rounded, s.stop, true),
          _ when s.stopping => ('正在减速停止', Icons.hourglass_bottom_rounded, null, false),
          _ when s.running => ('停止', Icons.pause_rounded, s.stop, true),
          _ when s.busy => ('等待设备确认', Icons.hourglass_top_rounded, null, false),
          _ when !s.fresh => ('等待设备状态', Icons.sync_rounded, null, false),
          _ when !s.homed => ('先回零', Icons.home_outlined, onOpenDevice, false),
          _ when s.speed <= 0 => ('调高速度后启动', Icons.play_arrow_rounded, null, false),
          _ => ('启动', Icons.play_arrow_rounded, s.canStart ? s.toggleRun : null, false),
        };
    final primary = action != null && !hot && label == '启动';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 56,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _RunButton(
                label: label,
                icon: icon,
                onTap: action,
                primary: primary,
                running: hot,
                // Firmware ramps `gain` 1 → 0 during a soft stop.
                progress: s.stopping ? s.gain : null,
              ),
            ),
            const SizedBox(width: 10),
            _EStop(onTap: s.connected ? s.emergencyStop : null),
          ],
        ),
      ),
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.primary,
    required this.running,
    this.progress,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary, running;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final fg = primary
        ? const Color(0xFF241832)
        : onTap == null
        ? OssmPalette.textDim
        : OssmPalette.text;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: primary
              ? const LinearGradient(
                  colors: [OssmPalette.pink, OssmPalette.magenta, OssmPalette.violet],
                )
              : null,
          color: primary
              ? null
              : running
              ? OssmPalette.surfaceHi
              : OssmPalette.surface,
          border: Border.all(
            color: running
                ? OssmPalette.pink.withValues(alpha: .6)
                : Colors.white.withValues(alpha: primary ? 0 : .07),
          ),
          boxShadow: primary
              ? [BoxShadow(color: OssmPalette.magenta.withValues(alpha: .35), blurRadius: 18)]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onTap!();
                },
          child: Stack(
            children: [
              if (progress != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress!.clamp(0, 1),
                        child: ColoredBox(
                          color: OssmPalette.magenta.withValues(alpha: .18),
                        ),
                      ),
                    ),
                  ),
                ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: fg, size: 22),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EStop extends StatelessWidget {
  const _EStop({required this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    const red = Color(0xFFFF6B88);
    return SizedBox(
      width: 112,
      child: Material(
        color: on ? const Color(0xFF3A1422) : const Color(0xFF231820),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: on ? OssmPalette.fault.withValues(alpha: .7) : const Color(0xFF3F2C38),
            width: 1.2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: on
              ? () {
                  HapticFeedback.heavyImpact();
                  onTap!();
                }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.front_hand_rounded,
                size: 18,
                color: on ? red : OssmPalette.textDim,
              ),
              const SizedBox(width: 6),
              Text(
                '紧急停止',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: on ? red : OssmPalette.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
