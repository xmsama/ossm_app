import 'package:flutter/material.dart';

import '../state/session_controller.dart';
import '../theme/palette.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key, required this.session});
  final SessionController session;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final link = session.transport;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '设备',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              '连接你的 OSSM，所有运动由设备本地执行。',
              style: TextStyle(color: OssmPalette.textMuted),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bluetooth_rounded,
                          color: OssmPalette.cyan,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            session.connected ? link.name : '寻找附近的设备',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      session.connected
                          ? session.status
                          : '打开设备电源，开启手机蓝牙并允许附近设备权限。',
                    ),
                    const SizedBox(height: 12),
                    if (session.connected)
                      OutlinedButton(
                        onPressed: session.disconnect,
                        child: const Text('停止并断开'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: link.scanning || link.connecting
                            ? null
                            : link.scan,
                        icon: const Icon(Icons.radar),
                        label: Text(
                          link.connecting
                              ? '正在连接…'
                              : link.scanning
                              ? '正在扫描…'
                              : '扫描设备',
                        ),
                      ),
                    if (link.scanning || link.connecting)
                      const LinearProgressIndicator(),
                    if (link.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          link.error!,
                          style: const TextStyle(color: OssmPalette.warning),
                        ),
                      ),
                    if (!session.connected &&
                        !link.scanning &&
                        link.devices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          '只显示兼容 OSSM 服务的设备。模拟器无法连接真实蓝牙。',
                          style: TextStyle(
                            fontSize: 12,
                            color: OssmPalette.textMuted,
                          ),
                        ),
                      ),
                    if (!session.connected)
                      ...link.devices.map(
                        (d) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(d.name),
                          subtitle: Text('${d.id} · ${d.rssi} dBm'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: link.connecting
                              ? null
                              : () => session.connect(d.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '回零与行程',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(session.homed ? '本次回零已确认' : '未回零，启动已锁定'),
                    const SizedBox(height: 6),
                    Text(
                      session.travelMm > 0
                          ? '已配置行程 ${session.travelMm.toStringAsFixed(1)} mm'
                          : '连接后读取设备行程',
                    ),
                    const Text(
                      '回零确认零点；可用行程需要按实际机械尺寸设置，不代表自动测量。',
                      style: TextStyle(
                        fontSize: 12,
                        color: OssmPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: session.canEdit && !session.running
                          ? () => _home(context)
                          : null,
                      icon: const Icon(Icons.home_outlined),
                      label: Text(session.homing ? '正在回零…' : '开始回零'),
                    ),
                    TextButton(
                      onPressed: session.canEdit && !session.running
                          ? () => _travel(context)
                          : null,
                      child: const Text('设置可用行程'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _row(
                    '电机',
                    session.fresh ? (session.online ? '在线' : '离线') : '—',
                  ),
                  _row(
                    '电压 / 温度',
                    session.fresh
                        ? '${session.voltage.toStringAsFixed(1)} V / ${session.tempC.toStringAsFixed(1)} °C'
                        : '—',
                  ),
                  _row(
                    '电流 / 位置',
                    session.fresh
                        ? '${session.current.toStringAsFixed(2)} A / ${session.positionMm.toStringAsFixed(1)} mm'
                        : '—',
                  ),
                  _row('固件版本', session.connected ? link.firmware : '—'),
                  _row(
                    '故障代码',
                    session.fresh
                        ? '0x${session.fault.toRadixString(16).padLeft(2, '0')}'
                        : '—',
                  ),
                  if (session.fault != 0 || session.machineState == 'fault')
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: OutlinedButton(
                        onPressed:
                            session.connected &&
                                !session.running &&
                                !session.homing
                            ? session.clearFault
                            : null,
                        child: const Text('检查设备后清除故障'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('离线演示'),
              subtitle: const Text('使用模拟设备体验操作，不发送蓝牙指令'),
              value: session.demo,
              onChanged: link.connecting || session.busy
                  ? null
                  : session.setDemo,
            ),
          ],
        );
      },
    ),
  );
  Widget _row(String label, String value) =>
      ListTile(dense: true, title: Text(label), trailing: Text(value));
  Future<void> _home(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('准备回零'),
        content: const Text('设备将低速收回并寻找机械端点。请移开行程内物品，确认机械结构允许触停，且实体急停可随时操作。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('开始回零'),
          ),
        ],
      ),
    );
    if (ok == true) await session.home();
  }

  Future<void> _travel(BuildContext context) async {
    final input = TextEditingController(
      text: session.travelMm.toStringAsFixed(0),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: const Text('可用行程'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('填写实际可安全运动的长度（10–400 mm），应留出机械端点余量。保存后需重新回零。'),
              TextField(
                controller: input,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  suffixText: 'mm',
                  labelText: '行程长度',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed:
                  (double.tryParse(input.text) ?? 0) >= 10 &&
                      (double.tryParse(input.text) ?? 401) <= 400
                  ? () => Navigator.pop(c, double.parse(input.text))
                  : null,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    // Dialog exit animation may still use its controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
    if (value != null) await session.setTravel(value);
  }
}
