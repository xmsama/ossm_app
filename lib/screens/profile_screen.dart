import 'package:flutter/material.dart';

import '../models/stroke_pattern.dart';
import '../state/session_controller.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../widgets/panel.dart';
import '../widgets/pattern_picker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.session});
  final SessionController session;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final s = session;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 64),
          children: [
            const PageHeader('我的', '预设和安全习惯只保存在这台手机，无需账号。'),
            Row(
              children: [
                const Expanded(child: PanelLabel('我的预设')),
                TextButton.icon(
                  onPressed: () => _save(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('保存当前'),
                ),
              ],
            ),
            if (s.presets.isEmpty)
              const Panel(
                child: Text(
                  '调好行程、速度和模式后点「保存当前」，下次一键载入。',
                  style: OssmType.secondary,
                ),
              )
            else
              for (final (i, p) in s.presets.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PresetCard(
                    preset: p,
                    onApply: () => s.applyPreset(i),
                    onDelete: () => s.removePreset(i),
                  ),
                ),
            const SizedBox(height: 16),
            const PanelLabel('安全'),
            const SizedBox(height: 8),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('速度上限', style: OssmType.body)),
                      Text(
                        '${s.speedLimit.round()}%',
                        style: OssmType.section.copyWith(color: OssmPalette.magenta),
                      ),
                    ],
                  ),
                  Slider(
                    value: s.speedLimit,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    onChanged: s.running || s.busy ? null : s.setSpeedLimit,
                  ),
                  const Text(
                    'App 端限制，控制页推杆上方的斜纹区不可进入。不替代设备端限位。',
                    style: OssmType.caption,
                  ),
                  const Divider(height: 28),
                  const Text('每次启动后自动停止', style: OssmType.body),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final n in const [0, 5, 10, 15, 30, 60])
                        ChoiceChip(
                          label: Text(n == 0 ? '不限' : '$n 分'),
                          selected: s.timerMinutes == n,
                          showCheckmark: false,
                          onSelected: s.running
                              ? null
                              : (_) {
                                  s.timerMinutes = n;
                                  s.savePreferences();
                                },
                        ),
                    ],
                  ),
                  const Divider(height: 28),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('切到后台时停止并断开'),
                    subtitle: const Text('离开前先急停，回来后需重新连接'),
                    value: s.stopOnBackground,
                    onChanged: (v) {
                      s.stopOnBackground = v;
                      s.savePreferences();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const PanelLabel('本次记录'),
            const SizedBox(height: 8),
            Panel(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: s.events.isEmpty
                  ? const Text('暂无记录', style: OssmType.secondary)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final e in s.events.take(10))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(e, style: OssmType.caption),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            const Text(
              'OSSM Controller 0.2.1\n无线停止依赖蓝牙连接，请始终保留实体急停。',
              textAlign: TextAlign.center,
              style: OssmType.caption,
            ),
          ],
        );
      },
    ),
  );

  Future<void> _save(BuildContext context) async {
    final input = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('保存预设'),
        content: TextField(
          controller: input,
          maxLength: 24,
          autofocus: true,
          decoration: const InputDecoration(labelText: '预设名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, input.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
    if (name != null) session.savePreset(name);
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.onApply,
    required this.onDelete,
  });
  final Map<String, dynamic> preset;
  final VoidCallback onApply, onDelete;

  @override
  Widget build(BuildContext context) {
    final pattern = StrokePattern
        .catalog[(preset['pattern'] as num).toInt().clamp(0, 6)];
    final depth = (preset['depth'] as num).round();
    final stroke = (preset['stroke'] as num).round();
    return Material(
      color: OssmPalette.surface.withValues(alpha: .78),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: .06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onApply,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 44,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OssmPalette.bgMid,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(
                  painter: PatternWavePainter(pattern: pattern, lit: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset['name'].toString(),
                      style: OssmType.body.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${pattern.name} · 速度 ${preset['speed']}% · 行程 ${depth - stroke}–$depth%',
                      style: OssmType.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '删除预设',
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
