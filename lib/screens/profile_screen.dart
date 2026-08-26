import 'package:flutter/material.dart';

import '../theme/palette.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            '我的',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: OssmPalette.text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '账号、偏好、关于。先占位。',
            style: TextStyle(fontSize: 13, color: OssmPalette.textMuted),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: OssmPalette.surfaceHi,
                  child: Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: OssmPalette.textMuted,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '未登录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: OssmPalette.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const _Row(label: '使用偏好'),
          const _Row(label: '安全与限位'),
          const _Row(label: '关于 OSSM'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: OssmPalette.text,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.chevron_right_rounded,
            color: OssmPalette.textDim,
          ),
        ],
      ),
    );
  }
}
