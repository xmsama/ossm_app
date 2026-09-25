import 'package:flutter/material.dart';

import '../ble/device_transport.dart';
import '../state/session_controller.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../widgets/panel.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key, required this.session});
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
            PageHeader(
              '设备',
              '运动由设备本地执行，手机只发送参数。',
              trailing: StateChip(label: s.stateLabel, tone: s.tone),
            ),
            _ConnectionPanel(session: s),
            if (s.faulted && s.connected) ...[
              const SizedBox(height: 12),
              _FaultPanel(session: s),
            ],
            const SizedBox(height: 12),
            _PrepPanel(
              session: s,
              onHome: () => _home(context),
              onTravel: () => _travel(context),
            ),
            const SizedBox(height: 12),
            _Telemetry(session: s),
            const SizedBox(height: 12),
            _StrategyPanel(session: s),
            const SizedBox(height: 12),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: SwitchListTile(
                title: const Text('离线演示'),
                subtitle: const Text('模拟设备体验操作，不发送蓝牙指令'),
                value: s.demo,
                onChanged: s.transport.connecting || s.busy ? null : s.setDemo,
              ),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _home(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('准备回零'),
        content: const Text(
          '滑杆将以约 20 mm/s 缓慢收回，碰到机械端点后退 7 mm 设为零点。'
          '请移开行程内的物品，并确保实体急停随时可用。',
        ),
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
        builder: (c, setState) {
          final v = double.tryParse(input.text);
          final valid = v != null && v >= 10 && v <= 400;
          return AlertDialog(
            title: const Text('可用行程'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('从零点起可安全伸出的长度（10–400 mm），请为机械端点留出余量。回零不会自动测量它，保存后需重新回零。'),
                const SizedBox(height: 16),
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
                onPressed: valid ? () => Navigator.pop(c, v) : null,
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
    // Dialog exit animation may still use its controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
    if (value != null) await session.setTravel(value);
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({required this.session});
  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final link = s.transport;
    if (s.connected) {
      return Panel(
        child: Row(
          children: [
            _IconBadge(
              icon: s.demo ? Icons.science_outlined : Icons.bluetooth_connected_rounded,
              color: OssmPalette.cyan,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(link.name, style: OssmType.section),
                  Text('固件 ${link.firmware}', style: OssmType.caption),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: s.disconnect,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('断开'),
            ),
          ],
        ),
      );
    }
    final busy = link.scanning || link.connecting;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _IconBadge(
                icon: Icons.bluetooth_searching_rounded,
                color: OssmPalette.magenta,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('寻找 OSSM', style: OssmType.section),
                    Text('打开设备电源，允许蓝牙和附近设备权限', style: OssmType.caption),
                  ],
                ),
              ),
              FilledButton(
                onPressed: busy ? null : link.scan,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(
                  link.connecting ? '连接中' : link.scanning ? '扫描中' : '扫描',
                ),
              ),
            ],
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (link.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                link.error!,
                style: const TextStyle(color: OssmPalette.warning, fontSize: 13),
              ),
            ),
          for (final d in link.devices)
            _DeviceRow(
              device: d,
              onTap: link.connecting ? null : () => s.connect(d.id),
            ),
          if (!busy && link.devices.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                '只显示兼容 OSSM 服务的设备（广播名 OSSM-S3）。',
                style: OssmType.caption,
              ),
            ),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, this.onTap});
  final NearbyDevice device;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final bars = device.rssi >= -60 ? 3 : device.rssi >= -75 ? 2 : 1;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            for (var i = 1; i <= 3; i++)
              Container(
                width: 4,
                height: 5.0 + i * 4,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: i <= bars ? OssmPalette.cyan : OssmPalette.track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name, style: OssmType.body),
                  Text('${device.rssi} dBm', style: OssmType.caption),
                ],
              ),
            ),
            const Text('连接', style: TextStyle(color: OssmPalette.magenta)),
            const Icon(Icons.chevron_right_rounded, color: OssmPalette.magenta),
          ],
        ),
      ),
    );
  }
}

class _FaultPanel extends StatelessWidget {
  const _FaultPanel({required this.session});
  final SessionController session;
  @override
  Widget build(BuildContext context) {
    final s = session;
    return Panel(
      tint: OssmPalette.fault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: OssmPalette.fault),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.faultText,
                  style: OssmType.section.copyWith(color: OssmPalette.fault),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '电机已断开输出。检查供电、线缆和机械卡滞后清除故障，清除后需要重新回零。',
            style: OssmType.secondary,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: !s.running && !s.homing && !s.busy ? s.clearFault : null,
            child: const Text('已检查，清除故障'),
          ),
        ],
      ),
    );
  }
}

/// The order the firmware enforces: connect → travel → home → start.
class _PrepPanel extends StatelessWidget {
  const _PrepPanel({
    required this.session,
    required this.onHome,
    required this.onTravel,
  });
  final SessionController session;
  final VoidCallback onHome, onTravel;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final editable = s.canEdit && !s.running;
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PanelLabel('启动前准备'),
          const SizedBox(height: 8),
          _Step(
            n: 1,
            done: s.connected,
            title: '连接设备',
            detail: s.connected ? s.transport.name : '在上方扫描并连接',
          ),
          _Step(
            n: 2,
            done: s.connected && s.travelMm > 0,
            title: '确认可用行程',
            detail: s.travelMm > 0
                ? '${s.travelMm.toStringAsFixed(0)} mm · 由你设定，回零不会测量'
                : '连接后读取',
            action: TextButton(
              onPressed: editable ? onTravel : null,
              child: const Text('修改'),
            ),
          ),
          _Step(
            n: 3,
            done: s.homed,
            active: s.homing,
            title: '回零',
            detail: s.homing
                ? '正在寻找机械端点…'
                : s.homed
                ? '零点已确认'
                : '每次上电或修改行程后都需要',
            last: true,
            action: s.homed && !s.homing
                ? TextButton(
                    onPressed: editable ? onHome : null,
                    child: const Text('重新回零'),
                  )
                : FilledButton(
                    onPressed: editable ? onHome : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(s.homing ? '回零中' : '开始'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.done,
    required this.title,
    required this.detail,
    this.active = false,
    this.last = false,
    this.action,
  });
  final int n;
  final bool done, active, last;
  final String title, detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = done
        ? OssmPalette.cyan
        : active
        ? OssmPalette.warning
        : OssmPalette.textDim;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? c.withValues(alpha: .18) : Colors.transparent,
                    border: Border.all(color: c, width: 1.4),
                  ),
                  child: done
                      ? Icon(Icons.check_rounded, size: 15, color: c)
                      : Text('$n', style: TextStyle(fontSize: 12, color: c)),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1.4,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: OssmPalette.track,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: OssmType.body.copyWith(fontWeight: FontWeight.w500)),
                  Text(detail, style: OssmType.caption),
                ],
              ),
            ),
          ),
          if (action != null)
            Align(alignment: Alignment.topRight, child: action),
        ],
      ),
    );
  }
}

class _Telemetry extends StatelessWidget {
  const _Telemetry({required this.session});
  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final f = s.fresh;
    String v(double x, int d, String u) => f ? '${x.toStringAsFixed(d)} $u' : '—';
    final tiles = [
      ('电压', v(s.voltage, 1, 'V'), null),
      ('电流', v(s.current, 2, 'A'), null),
      ('温度', v(s.tempC, 0, '°C'), f && s.tempC >= 70 ? OssmPalette.warning : null),
      ('位置', v(s.positionMm, 1, 'mm'), null),
      ('电机', f ? (s.online ? '在线' : '离线') : '—', f && !s.online ? OssmPalette.fault : null),
      ('报警', f ? (s.fault == 0 ? '无' : '0x${s.fault.toRadixString(16).toUpperCase()}') : '—',
          f && s.fault != 0 ? OssmPalette.fault : null),
    ];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PanelLabel('实时状态'),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, value, color) in tiles)
                    Container(
                      width: w,
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      decoration: BoxDecoration(
                        color: OssmPalette.bgMid,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: OssmType.caption),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: color ?? OssmPalette.text,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StrategyPanel extends StatelessWidget {
  const _StrategyPanel({required this.session});
  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final enabled = s.canEdit && !s.running;
    Widget option(int value, String title, String detail) {
      final on = s.strategy == value;
      return Expanded(
        child: GestureDetector(
          onTap: enabled && !on ? () => s.setStrategy(value) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: on ? OssmPalette.surfaceHi : OssmPalette.bgMid,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: on
                    ? OssmPalette.magenta.withValues(alpha: .7)
                    : Colors.transparent,
              ),
            ),
            child: Opacity(
              opacity: enabled || on ? 1 : .5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: OssmType.body.copyWith(fontWeight: FontWeight.w500)),
                  Text(detail, style: OssmType.caption),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PanelLabel('运动算法'),
          const SizedBox(height: 10),
          Row(
            children: [
              option(0, '关键点', '驱动器自带加减速，力度更干脆'),
              const SizedBox(width: 8),
              option(2, '位置流', '每 10 ms 平滑插值，更柔顺'),
            ],
          ),
          const SizedBox(height: 8),
          const Text('切换时电机会短暂断电，只能在停止时修改。', style: OssmType.caption),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: color, size: 22),
  );
}
