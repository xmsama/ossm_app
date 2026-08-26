import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/palette.dart';

class RunPill extends StatelessWidget {
  const RunPill({
    super.key,
    required this.running,
    required this.onToggle,
  });

  final bool running;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: running
              ? const LinearGradient(
                  colors: [OssmPalette.pink, OssmPalette.violet],
                )
              : null,
          color: running ? null : OssmPalette.surface,
          border: running
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: running
              ? [
                  BoxShadow(
                    color: OssmPalette.pink.withValues(alpha: 0.35),
                    blurRadius: 18,
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 18,
              color: OssmPalette.text,
            ),
            const SizedBox(width: 6),
            Text(
              running ? '运行中' : '轻触启动',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: OssmPalette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
