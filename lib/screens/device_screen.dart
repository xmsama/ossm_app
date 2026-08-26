import 'package:flutter/material.dart';

import '../state/session_controller.dart';
import '../theme/palette.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const Text(
                '设备',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: OssmPalette.text,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '连接、回零、固件这类放这里。还没定。',
                style: TextStyle(fontSize: 13, color: OssmPalette.textMuted),
              ),
              const SizedBox(height: 20),
              _Tile(
                label: '连接',
                value: session.connected ? '已连接（模拟）' : '未连接',
              ),
              _Tile(
                label: '回零',
                value: session.homed
                    ? '可用 ${session.travelMm.round()} mm'
                    : '未标定',
              ),
              _Tile(
                label: '总线',
                value: '${session.voltage.toStringAsFixed(1)} V  ·  ${session.tempC.round()}℃',
              ),
              const _Tile(label: '固件', value: '—'),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: OssmPalette.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: OssmPalette.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: OssmPalette.text,
            ),
          ),
        ],
      ),
    );
  }
}
