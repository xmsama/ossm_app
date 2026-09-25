import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ble/ble_transport.dart';
import '../ble/demo_transport.dart';
import '../ble/device_transport.dart';
import '../ble/rad_protocol.dart';
import '../models/stroke_pattern.dart';

/// Coarse visual tone of the machine state.
enum DeviceTone { off, waiting, ready, live, fault }

class SessionController extends ChangeNotifier {
  SessionController({
    DeviceTransport? transport,
    this.persist = true,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _attach(transport ?? BleTransport());
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    if (persist) unawaited(_load());
  }
  final bool persist;
  final DateTime Function() _now;
  late DeviceTransport transport;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _watchdog, _debounce, _toast;
  DateTime? _lastState, _deadline;
  DateTime? _connectedAt, _startAt;
  bool _awaitingStart = false;
  bool _awaitingStop = false, _stopAcknowledged = false;
  int _generation = 0;
  bool _disposed = false, _sending = false, _dirty = false;
  bool _homeRequested = false, _sawHoming = false;
  DateTime? _homeAt;
  bool busy = false;
  String? message;
  final List<String> events = [];
  final List<Map<String, dynamic>> presets = [];
  double speedLimit = 40;
  int timerMinutes = 10;
  bool stopOnBackground = true;
  static const minSpan = 1.0;
  bool homed = false, online = false, running = false;
  double travelMm = 0, speed = 0, depth = 60, stroke = 40, sensation = 50;
  double voltage = 0, tempC = 0, current = 0, positionMm = 0, gain = 1;
  int patternIndex = 0, fault = 0, strategy = 0;
  String machineState = 'unknown';
  bool get connected => transport.connected;
  bool get demo => transport.demo;
  bool get fresh =>
      _lastState != null && _now().difference(_lastState!).inSeconds < 5;
  bool get canControl =>
      connected &&
      transport.hasLease &&
      fresh &&
      online &&
      fault == 0 &&
      machineState != 'fault';
  bool get canEdit =>
      canControl &&
      !busy &&
      !_awaitingStart &&
      !_awaitingStop &&
      !homing &&
      machineState != 'stopping';
  bool get homing => machineState == 'homing' || _homeRequested;
  bool get canStart =>
      canEdit && homed && travelMm > 0 && speed > 0 && stroke > 0 && !running;
  int? get remainingSeconds => _deadline == null
      ? null
      : math.max(0, _deadline!.difference(_now()).inSeconds);
  StrokePattern get pattern => StrokePattern.catalog[patternIndex];
  double get shallow => (depth - stroke).clamp(0, 100).toDouble();
  double get depthMm => depth / 100 * travelMm;
  double get strokeMm => stroke / 100 * travelMm;
  double get shallowMm => shallow / 100 * travelMm;
  bool get stopping => machineState == 'stopping' || _awaitingStop;
  bool get faulted => fault != 0 || machineState == 'fault';

  /// Short machine state for the status chip.
  String get stateLabel {
    if (!connected) return '未连接';
    if (!fresh) return '同步中';
    if (faulted) return '故障';
    if (!online) return '电机离线';
    if (homing) return '回零中';
    if (stopping) return '停止中';
    if (running) return '运行中';
    if (!homed) return '未回零';
    return '就绪';
  }

  DeviceTone get tone {
    if (!connected) return DeviceTone.off;
    if (faulted || (fresh && !online)) return DeviceTone.fault;
    if (running && !stopping) return DeviceTone.live;
    if (fresh && homed && !homing && !stopping) return DeviceTone.ready;
    return DeviceTone.waiting;
  }

  /// Modbus drive alarm codes (firmware Constants.h / YZ-Modbus.md).
  static String describeFault(int code) => switch (code) {
    0 => '正常',
    0x10 => '驱动器电池报警',
    0x12 => '电机堵转',
    0x14 => '失速 / 跟随超差',
    0x15 => '过压（超过 52 V）',
    0x20 => '驱动器通信中断',
    _ => '驱动器报警',
  };
  String get faultText {
    if (fault == 0 && machineState == 'fault') return '总线或驱动故障';
    final hex = '0x${fault.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    return fault == 0 ? describeFault(0) : '${describeFault(fault)} · $hex';
  }

  String get status {
    if (!connected) return '请在设备页连接 OSSM';
    if (!fresh) return '正在等待设备状态';
    if (fault != 0 || machineState == 'fault') return '设备故障，请停止并检查设备';
    if (!online) return '电机离线，请检查供电与总线';
    if (homing) return '正在回零，请保持行程内无障碍';
    if (_awaitingStop) return '正在等待设备停止确认';
    if (_awaitingStart) return '正在等待设备启动确认';
    if (machineState == 'stopping') return '正在停止';
    if (running) return '运行中';
    if (!homed) return '请先在设备页完成回零';
    if (speed == 0) return '已就绪，调节速度后启动';
    return '已就绪';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _log(String text) {
    if (_disposed) return;
    message = text;
    _toast?.cancel();
    _toast = Timer(const Duration(seconds: 5), () {
      message = null;
      _notify();
    });
    events.insert(
      0,
      '${DateTime.now().toIso8601String().substring(11, 19)}  $text',
    );
    if (events.length > 40) events.removeLast();
    _notify();
  }

  void _attach(DeviceTransport value) {
    transport = value;
    transport.addListener(_transportChanged);
    _subscription = transport.states.listen(_state);
  }

  void _transportChanged() {
    if (connected) _connectedAt ??= _now();
    if (!connected) {
      _generation++;
      _debounce?.cancel();
      _dirty = false;
      homed = false;
      running = false;
      online = false;
      _lastState = null;
      _connectedAt = null;
      _awaitingStart = false;
      _awaitingStop = false;
      busy = false;
      _deadline = null;
      _homeRequested = false;
      travelMm = 0;
      machineState = 'unknown';
    }
    _notify();
  }

  void _state(Map<String, dynamic> data) {
    if (_disposed || !connected) return;
    double number(String key, double fallback) {
      final v = data[key];
      return v is num && v.isFinite ? v.toDouble() : fallback;
    }

    if (data['state'] is! String ||
        data['online'] is! bool ||
        data['running'] is! bool ||
        data['fault'] is! num) {
      return;
    }
    _lastState = _now();
    machineState = data['state'];
    online = data['online'] == true;
    final wasRunning = running;
    running = data['running'] == true;
    if (_awaitingStop &&
        _stopAcknowledged &&
        !running &&
        machineState != 'homing' &&
        machineState != 'stopping') {
      _awaitingStop = false;
    }
    if (running) _awaitingStart = false;
    if (wasRunning && !running) _deadline = null;
    fault = (data['fault'] as num).toInt();
    voltage = number('voltage', voltage);
    tempC = number('temp', tempC);
    current = number('current', current);
    positionMm = number('positionMm', positionMm);
    gain = number('gain', gain).clamp(0, 1).toDouble();
    travelMm = number('travelMm', travelMm);
    strategy = number('strategy', strategy.toDouble()).toInt();
    if (!_dirty && !_sending && !busy) {
      speed = number('speed', speed).clamp(0, 100);
      depth = number('depth', depth).clamp(1, 100);
      stroke = number('stroke', stroke).clamp(0, depth);
      sensation = number('sensation', sensation).clamp(0, 100);
      patternIndex = number(
        'pattern',
        patternIndex.toDouble(),
      ).toInt().clamp(0, 6);
    }
    if (data['homed'] is bool) homed = data['homed'] == true;
    if (_homeRequested && machineState == 'homing') _sawHoming = true;
    if (_homeRequested &&
        machineState == 'ready' &&
        (_sawHoming || data['homed'] == true)) {
      homed = true;
      _homeRequested = false;
      _log('回零完成');
    }
    if (!online ||
        fault != 0 ||
        machineState == 'fault' ||
        machineState == 'boot') {
      homed = false;
      _homeRequested = false;
    }
    if (!running && machineState != 'ready') _deadline = null;
    if (running && speed > speedLimit && !busy) unawaited(stop());
    _notify();
  }

  Future<void> connect(String id) async {
    await transport.connect(id);
    if (!connected) return;
    await _guard(() async {
      final result = await transport.request(
        'setting.read',
        path: 'motor.travelMm',
      );
      final mm = result['value'];
      if (mm is! num || !mm.isFinite || mm < 10 || mm > 400) {
        throw const DeviceException('固件行程数据无效');
      }
      travelMm = mm.toDouble();
      _log('已连接 ${transport.name}，请回零后启动');
    });
  }

  Future<void> setDemo(bool enabled) async {
    await disconnect();
    await _subscription?.cancel();
    transport.removeListener(_transportChanged);
    transport.dispose();
    _attach(enabled ? DemoTransport() : BleTransport());
    if (enabled) await connect('demo');
    _notify();
  }

  Future<void> disconnect() async {
    if (connected && transport.hasLease) await emergencyStop();
    await transport.disconnect();
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      _log(e.toString());
    }
    _notify();
  }

  Map<String, dynamic> get parameters => {
    'speed': speed.round().clamp(0, speedLimit.round()),
    'stroke': stroke.round(),
    'depth': depth.round(),
    'sensation': sensation.round(),
    'pattern': patternIndex,
  };
  void _changed() {
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _flush);
    _notify();
  }

  Future<void> _flush() async {
    if (_sending || !_dirty || !canEdit) return;
    final generation = _generation;
    _dirty = false;
    _sending = true;
    try {
      await transport.request('session.apply', args: parameters);
    } catch (e) {
      _log('参数未确认：$e');
      if (generation == _generation) await emergencyStop();
    } finally {
      _sending = false;
      if (_dirty && generation == _generation) unawaited(_flush());
      _notify();
    }
  }

  void nudgeSpeed(double delta) {
    if (!canEdit) return;
    speed = (speed + delta).clamp(0, speedLimit);
    _changed();
  }

  void setSpeed(double value) {
    if (!canEdit) return;
    speed = value.clamp(0, speedLimit).roundToDouble();
    _changed();
  }

  /// 0 KeyPoint, 2 PositionStream. Firmware briefly cuts motor power on
  /// change, so only allowed while stopped. 1 (VelocityStream) does not move
  /// on the Modbus drive and is not offered.
  Future<void> setStrategy(int value) async {
    if (!canEdit || running || (value != 0 && value != 2)) return;
    busy = true;
    await _guard(() async {
      await transport.request('session.apply', args: {'strategy': value});
      strategy = value;
      _log(value == 0 ? '已切换为关键点运动' : '已切换为平滑位置流');
    });
    busy = false;
    _notify();
  }

  void setSensation(double value) {
    if (!canEdit) return;
    sensation = value.clamp(0, 100);
    _changed();
  }

  void selectPattern(int index) {
    if (!canEdit || index < 0 || index > 6) return;
    patternIndex = index;
    _changed();
  }

  void setShallow(double value) {
    if (!canEdit) return;
    stroke = (depth - value).clamp(minSpan, depth);
    _changed();
  }

  void setDeep(double value) {
    if (!canEdit) return;
    final sh = shallow;
    depth = value.clamp(sh + minSpan, 100);
    stroke = depth - sh;
    _changed();
  }

  void shiftDepth(double delta) {
    if (!canEdit) return;
    depth = (depth + delta).clamp(stroke, 100);
    _changed();
  }

  Future<void> toggleRun() async {
    if (running || homing) {
      await stop();
      return;
    }
    if (!canStart) {
      _log(status);
      return;
    }
    busy = true;
    _awaitingStart = true;
    _startAt = _now();
    _debounce?.cancel();
    _dirty = false;
    final generation = ++_generation;
    _notify();
    try {
      await transport.request(
        'session.apply',
        args: {...parameters, 'running': true},
      );
      if (generation != _generation) return;
      _deadline = timerMinutes == 0
          ? null
          : _now().add(Duration(minutes: timerMinutes));
      _log('启动命令已确认，等待设备运行状态');
    } catch (e) {
      _log('启动未确认：$e');
      if (generation == _generation) await emergencyStop();
    } finally {
      if (generation == _generation) busy = false;
      _notify();
    }
  }

  Future<void> stop() => _stop(false);
  Future<void> emergencyStop() => _stop(true);
  Future<void> _stop(bool emergency) async {
    _awaitingStart = false;
    _awaitingStop = connected;
    _stopAcknowledged = false;
    _generation++;
    _debounce?.cancel();
    _dirty = false;
    _deadline = null;
    _homeRequested = false;
    busy = true;
    _notify();
    try {
      if (connected && transport.hasLease) {
        await transport.request(
          'ossm.command',
          args: {'command': emergency ? 'go:estop' : 'go:softEnd'},
          urgent: true,
        );
        _stopAcknowledged = true;
        _log(emergency ? '急停命令已确认' : '停止命令已确认');
      }
    } catch (e) {
      _log('停止未确认，请使用实体急停。$e');
      await transport.disconnect();
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> home() async {
    if (!canEdit || running) return;
    homed = false;
    _homeRequested = true;
    _sawHoming = false;
    _homeAt = _now();
    _notify();
    try {
      await transport.request('ossm.command', args: {'command': 'go:home'});
    } catch (e) {
      _homeRequested = false;
      _log('回零失败：$e');
    }
    _notify();
  }

  Future<void> clearFault() async {
    if (!connected || busy || running || homing) return;
    await _guard(() async {
      await transport.request(
        'ossm.command',
        args: {'command': 'go:clearFault'},
      );
      _log('已请求清除故障，请确认设备状态并重新回零');
    });
  }

  Future<void> setTravel(double mm) async {
    if (!canEdit || running || !mm.isFinite || mm < 10 || mm > 400) return;
    busy = true;
    await _guard(() async {
      await transport.request(
        'setting.write',
        path: 'motor.travelMm',
        args: {'value': mm},
      );
      final result = await transport.request(
        'setting.read',
        path: 'motor.travelMm',
      );
      if (result['value'] is! num) throw const DeviceException('行程读取失败');
      travelMm = (result['value'] as num).toDouble();
      homed = false;
      _log('可用行程已保存，请重新回零');
    });
    busy = false;
    _notify();
  }

  void _tick() {
    if (_disposed) return;
    if (connected &&
        !fresh &&
        !busy &&
        _connectedAt != null &&
        _now().difference(_connectedAt!).inSeconds >= 5) {
      _log('设备状态超过 5 秒未更新，正在停止并断开');
      unawaited(disconnect());
    }
    if (_homeRequested &&
        _homeAt != null &&
        _now().difference(_homeAt!).inSeconds > 30) {
      _log('回零超时');
      unawaited(emergencyStop());
    }
    if (_awaitingStart &&
        _startAt != null &&
        _now().difference(_startAt!).inSeconds >= 5) {
      _log('设备未确认进入运行状态');
      unawaited(emergencyStop());
    }
    if (_deadline != null && !_now().isBefore(_deadline!)) {
      _deadline = null;
      unawaited(stop());
    }
    _notify();
  }

  void onBackground() {
    if (stopOnBackground && connected) unawaited(disconnect());
  }

  Future<void> _load() async {
    try {
      final store = await SharedPreferences.getInstance();
      speedLimit = (store.getDouble('speedLimit') ?? 40).clamp(5, 100);
      timerMinutes = (store.getInt('timerMinutes') ?? 10).clamp(0, 60);
      stopOnBackground = store.getBool('stopOnBackground') ?? true;
      final saved = jsonDecode(store.getString('presets') ?? '[]');
      if (saved is List) {
        presets.addAll(
          saved
              .whereType<Map>()
              .map((p) => Map<String, dynamic>.from(p))
              .where(
                (p) =>
                    p['name'] is String &&
                    [
                      'speed',
                      'depth',
                      'stroke',
                      'sensation',
                      'pattern',
                    ].every((k) => p[k] is num && (p[k] as num).isFinite),
              ),
        );
      }
    } catch (_) {
      _log('无法读取本地偏好，使用默认值');
    }
    _notify();
  }

  Future<void> savePreferences() async {
    _notify();
    if (!persist) return;
    await _guard(() async {
      final store = await SharedPreferences.getInstance();
      await store.setDouble('speedLimit', speedLimit);
      await store.setInt('timerMinutes', timerMinutes);
      await store.setBool('stopOnBackground', stopOnBackground);
      await store.setString('presets', jsonEncode(presets));
    });
  }

  void setSpeedLimit(double value) {
    speedLimit = value.clamp(5, 100);
    if (speed > speedLimit) {
      speed = speedLimit;
      if (running) unawaited(stop());
    }
    unawaited(savePreferences());
  }

  void savePreset(String name) {
    if (name.trim().isEmpty) return;
    presets.add({'name': name.trim(), ...parameters});
    unawaited(savePreferences());
    _log('已保存预设');
  }

  void removePreset(int index) {
    presets.removeAt(index);
    unawaited(savePreferences());
  }

  void applyPreset(int index) {
    if (!canEdit || running) {
      _log('请连接设备并停止后载入预设');
      return;
    }
    final p = presets[index];
    speed = (p['speed'] as num).toDouble().clamp(0, speedLimit);
    depth = (p['depth'] as num).toDouble().clamp(1, 100);
    stroke = (p['stroke'] as num).toDouble().clamp(1, depth);
    sensation = (p['sensation'] as num).toDouble().clamp(0, 100);
    patternIndex = (p['pattern'] as num).toInt().clamp(0, 6);
    _changed();
    _log('预设已载入，点击启动后运行');
  }

  @override
  void dispose() {
    _disposed = true;
    _watchdog?.cancel();
    _toast?.cancel();
    _debounce?.cancel();
    unawaited(_subscription?.cancel());
    transport.removeListener(_transportChanged);
    transport.dispose();
    super.dispose();
  }
}
