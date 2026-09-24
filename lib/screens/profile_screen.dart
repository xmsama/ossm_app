import 'package:flutter/material.dart';

import '../state/session_controller.dart';
import '../theme/palette.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.session});
  final SessionController session;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListenableBuilder(
      listenable: session,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '我的',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            '你的习惯，留在这台手机。无需账号。',
            style: TextStyle(color: OssmPalette.textMuted),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '速度上限  ${session.speedLimit.round()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: session.speedLimit,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    onChanged: session.running || session.busy
                        ? null
                        : session.setSpeedLimit,
                  ),
                  const Text(
                    '默认上限 40%。这是 App 操作限制，不替代设备端限位。',
                    style: TextStyle(
                      color: OssmPalette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: session.timerMinutes,
                    decoration: const InputDecoration(labelText: '每次启动后自动停止'),
                    items: [0, 5, 10, 15, 30, 60]
                        .map(
                          (n) => DropdownMenuItem(
                            value: n,
                            child: Text(n == 0 ? '不设定时' : '$n 分钟'),
                          ),
                        )
                        .toList(),
                    onChanged: session.running
                        ? null
                        : (n) {
                            if (n != null) {
                              session.timerMinutes = n;
                              session.savePreferences();
                            }
                          },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('切到后台时停止并断开'),
                    subtitle: const Text('返回 App 后需手动重新连接'),
                    value: session.stopOnBackground,
                    onChanged: (v) {
                      session.stopOnBackground = v;
                      session.savePreferences();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '我的预设',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: () => _save(context),
                icon: const Icon(Icons.add),
                label: const Text('保存当前'),
              ),
            ],
          ),
          if (session.presets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '调好速度、行程和模式后，保存为自己的预设。',
                style: TextStyle(color: OssmPalette.textMuted),
              ),
            ),
          ...session.presets.asMap().entries.map(
            (entry) => Card(
              child: ListTile(
                title: Text(entry.value['name'].toString()),
                subtitle: Text(
                  '速度 ${entry.value['speed']}% · 行程 ${entry.value['stroke']}%',
                ),
                onTap: () => session.applyPreset(entry.key),
                trailing: IconButton(
                  tooltip: '删除预设',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => session.removePreset(entry.key),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '本次连接记录',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (session.events.isEmpty)
            const Text('暂无记录', style: TextStyle(color: OssmPalette.textMuted)),
          ...session.events
              .take(12)
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    e,
                    style: const TextStyle(
                      fontSize: 12,
                      color: OssmPalette.textMuted,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 24),
          const Text(
            'OSSM Controller · 0.2.0\n蓝牙参数控制 · 设备本地运动\n无线停止依赖连接，请保留实体急停。',
            style: TextStyle(fontSize: 12, color: OssmPalette.textMuted),
          ),
        ],
      ),
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
