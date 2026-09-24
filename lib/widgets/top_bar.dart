import 'package:flutter/material.dart';

import '../theme/palette.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.connected, this.voltage, this.tempC});
  final bool connected;
  final double? voltage, tempC;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
    child: Row(
      children: [
        const Icon(Icons.bolt_rounded, color: OssmPalette.pink, size: 28),
        const SizedBox(width: 8),
        const Text(
          'OSSM',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.bluetooth,
          size: 16,
          color: connected ? OssmPalette.cyan : OssmPalette.textDim,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  voltage == null ? '— V' : '${voltage!.toStringAsFixed(1)} V',
                  style: const TextStyle(
                    color: OssmPalette.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  tempC == null ? '— °C' : '${tempC!.toStringAsFixed(0)} °C',
                  style: const TextStyle(
                    color: OssmPalette.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
