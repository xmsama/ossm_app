import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_transport.dart';
import 'rad_protocol.dart';

class BleTransport extends DeviceTransport {
  BluetoothDevice? _device;
  final Map<String, BluetoothCharacteristic> _chars = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final _states = StreamController<Map<String, dynamic>>.broadcast();
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  Future<void> _queue = Future.value();
  Timer? _renew;
  Timer? _poll;
  int _id = 0, _epoch = 0;
  int? _lease;
  bool _connected = false, _connecting = false, _scanning = false;
  bool _reading = false, _renewing = false, _disposed = false;
  String _name = '', _firmware = '—';
  String? _error;
  List<NearbyDevice> _devices = [];
  @override
  bool get connected => _connected;
  @override
  bool get connecting => _connecting;
  @override
  bool get scanning => _scanning;
  @override
  bool get hasLease => _connected && _lease != null;
  @override
  String get name => _name;
  @override
  String get firmware => _firmware;
  @override
  String? get error => _error;
  @override
  List<NearbyDevice> get devices => List.unmodifiable(_devices);
  @override
  Stream<Map<String, dynamic>> get states => _states.stream;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> scan() async {
    if (_scanning || _connecting || _connected) return;
    _error = null;
    _devices = [];
    _scanning = true;
    _notify();
    StreamSubscription<List<ScanResult>>? sub;
    try {
      if (!await FlutterBluePlus.isSupported) {
        throw const DeviceException('此设备不支持蓝牙，请使用 Android 真机');
      }
      sub = FlutterBluePlus.onScanResults.listen(
        (results) {
          _devices =
              results
                  .map(
                    (r) => NearbyDevice(
                      r.device.remoteId.str,
                      r.advertisementData.advName.isEmpty
                          ? 'OSSM-S3'
                          : r.advertisementData.advName,
                      r.rssi,
                    ),
                  )
                  .toList()
                ..sort((a, b) => b.rssi.compareTo(a.rssi));
          _notify();
        },
        onError: (Object e) {
          _error = '扫描失败：$e';
          _notify();
        },
      );
      await FlutterBluePlus.startScan(
        withServices: [Guid(RadProtocol.service)],
        timeout: const Duration(seconds: 12),
        androidUsesFineLocation: false,
      );
      await FlutterBluePlus.isScanning.where((v) => !v).first;
    } catch (e) {
      _error = '无法扫描，请开启蓝牙并允许附近设备权限。$e';
    } finally {
      await sub?.cancel();
      _scanning = false;
      _notify();
    }
  }

  @override
  Future<void> connect(String id) async {
    if (_connecting || _connected) return;
    _connecting = true;
    _error = null;
    _notify();
    try {
      await FlutterBluePlus.stopScan();
      _device = BluetoothDevice.fromId(id);
      await _device!.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
        mtu: 512,
      );
      _subscriptions.add(
        _device!.connectionState.listen((s) {
          if (s == BluetoothConnectionState.disconnected) {
            _error = '设备已断开，请重新连接';
            _invalidate();
            _notify();
          }
        }),
      );
      final services = await _device!.discoverServices();
      final service = services
          .where((s) => s.uuid == Guid(RadProtocol.service))
          .firstOrNull;
      if (service == null) throw const DeviceException('不是兼容的 OSSM 设备');
      for (final suffix in [
        '0002',
        '0005',
        '1000',
        '1100',
        '2000',
        '2010',
        '2100',
      ]) {
        final c = service.characteristics
            .where((c) => c.uuid == Guid(RadProtocol.characteristic(suffix)))
            .firstOrNull;
        if (c == null) throw DeviceException('固件缺少必要蓝牙特征 $suffix');
        _chars[suffix] = c;
      }
      final protocol = RadProtocol.decode(await _chars['0002']!.read());
      if (protocol['version'] != 1 || protocol['protocol'] != 'rad-ble') {
        throw const DeviceException('不支持此固件协议版本');
      }
      final identity = RadProtocol.decode(await _chars['0005']!.read());
      _name = identity['name']?.toString() ?? 'OSSM-S3';
      _firmware = identity['firmwareVersion']?.toString() ?? '—';
      for (final suffix in ['1100', '2000', '2010', '2100']) {
        final c = _chars[suffix]!;
        _subscriptions.add(
          c.onValueReceived.listen((bytes) => _receive(suffix, bytes)),
        );
        await c.setNotifyValue(true);
      }
      _connected = true;
      final acquired = await request('control.acquire', args: {'ttl': 10});
      _lease = (acquired['lease'] as num?)?.toInt();
      if (_lease == null || _lease == 0) {
        throw const DeviceException('固件未返回控制权限');
      }
      // A connection never resumes motion, including a quick reconnect during ramp-down.
      await request(
        'ossm.command',
        args: {'command': 'go:estop'},
        urgent: true,
      );
      await _readState();
      _renew = Timer.periodic(const Duration(seconds: 3), (_) => _renewLease());
      // Full ATT reads also work when notifications exceed the negotiated MTU.
      _poll = Timer.periodic(const Duration(seconds: 1), (_) => _readState());
    } catch (e) {
      _error = '连接失败：$e';
      await disconnect();
    } finally {
      _connecting = false;
      _notify();
    }
  }

  void _receive(String suffix, List<int> bytes) {
    if (bytes.isEmpty || _disposed) return;
    Map<String, dynamic> value;
    try {
      value = RadProtocol.decode(bytes);
    } catch (_) {
      return;
    }
    if (suffix == '1100') {
      final id = value['id'];
      if (value['stage'] != 'completed' && value['stage'] != 'failed') return;
      final pending = _pending.remove(id);
      if (pending == null) return;
      if (value['ok'] == true) {
        pending.complete(
          Map<String, dynamic>.from(value['result'] as Map? ?? {}),
        );
      } else {
        pending.completeError(
          DeviceException('${value['code']}：${value['message'] ?? '设备拒绝命令'}'),
        );
      }
    } else if (suffix == '2000') {
      if (value.containsKey('online') && value.containsKey('speed')) {
        _states.add(value);
      }
    } else if (suffix == '2100' &&
        [
          'control.lease.expired',
          'control.lease.released',
        ].contains(value['event'])) {
      _error = '控制权限已失效，请重新连接';
      unawaited(disconnect());
    }
  }

  Future<void> _readState() async {
    if (_reading || !_connected) return;
    _reading = true;
    try {
      _receive('2000', await _chars['2000']!.read());
    } catch (_) {
      /* Session watchdog handles stale telemetry. */
    } finally {
      _reading = false;
    }
  }

  Future<void> _renewLease() async {
    if (_renewing || !hasLease) return;
    final epoch = _epoch;
    _renewing = true;
    try {
      await request('control.renew', args: {'ttl': 10});
    } catch (e) {
      if (epoch != _epoch) return;
      _error = '控制权限续期失败：$e';
      await disconnect();
    } finally {
      _renewing = false;
    }
  }

  @override
  Future<Map<String, dynamic>> request(
    String op, {
    Map<String, dynamic> args = const {},
    String? path,
    bool urgent = false,
  }) {
    if (urgent) {
      _epoch++; // Drop queued parameter/start commands before stopping.
    }
    final epoch = _epoch;
    Future<Map<String, dynamic>> send() async {
      if (!_connected || epoch != _epoch) {
        throw const DeviceException('连接已失效或命令已取消');
      }
      final id = ++_id;
      final bytes = RadProtocol.encode(
        id,
        op,
        args: args,
        path: path,
        lease: _lease,
      );
      final pending = Completer<Map<String, dynamic>>();
      _pending[id] = pending;
      // Attach error handling before the write, since disconnect can occur during it.
      final response = pending.future.timeout(const Duration(seconds: 4));
      unawaited(response.catchError((Object _) => <String, dynamic>{}));
      Timer? fallback;
      try {
        if (bytes.length > (_device!.mtuNow - 3)) {
          throw const DeviceException('蓝牙 MTU 过小，请重新连接');
        }
        await _chars['1000']!.write(bytes, timeout: 3);
        fallback = Timer(const Duration(milliseconds: 800), () async {
          if (!_pending.containsKey(id)) return;
          try {
            _receive('1100', await _chars['1100']!.read());
          } catch (_) {}
        });
        return await response;
      } finally {
        fallback?.cancel();
        _pending.remove(id);
      }
    }

    if (urgent) return send();
    final next = _queue.then((_) => send());
    _queue = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  void _invalidate() {
    _connected = false;
    _lease = null;
    _epoch++;
    _renew?.cancel();
    _poll?.cancel();
    for (final pending in _pending.values) {
      if (!pending.isCompleted) {
        pending.completeError(const DeviceException('蓝牙连接已断开'));
      }
    }
    _pending.clear();
  }

  @override
  Future<void> disconnect() async {
    _invalidate();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    try {
      await _device?.disconnect();
    } catch (_) {}
    _chars.clear();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    unawaited(_states.close());
    super.dispose();
  }
}
