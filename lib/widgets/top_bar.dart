import 'package:flutter/material.dart';

import '../theme/palette.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.connected,
    required this.voltage,
    required this.tempC,
    required this.battery,
  });

  final bool connected;
  final double voltage;
  final double tempC;
  final int battery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 16, 0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [OssmPalette.pink, OssmPalette.violet],
              ),
              boxShadow: [
                BoxShadow(
                  color: OssmPalette.magenta.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OSSM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: OssmPalette.text,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.bluetooth_rounded,
                    size: 13,
                    color: connected
                        ? OssmPalette.cyan
                        : OssmPalette.textDim,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    connected ? '已连接' : '未连接',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: connected
                          ? OssmPalette.textMuted
                          : OssmPalette.textDim,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          _Chip(text: '${voltage.toStringAsFixed(1)} V'),
          const SizedBox(width: 6),
          _Chip(text: '${tempC.round()}°'),
          const SizedBox(width: 6),
          _Battery(percent: battery),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: OssmPalette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: OssmPalette.textMuted,
        ),
      ),
    );
  }
}

class _Battery extends StatelessWidget {
  const _Battery({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: OssmPalette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.battery_full_rounded,
            size: 13,
            color: percent > 20 ? OssmPalette.connected : OssmPalette.warning,
          ),
          const SizedBox(width: 2),
          Text(
            '$percent%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: OssmPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
