import 'dart:async';

import 'device_transport.dart';

/// Explicit offline simulator. Never creates a Bluetooth connection.
class DemoTransport extends DeviceTransport {
  final _states = StreamController<Map<String, dynamic>>.broadcast();
  final Map<String, dynamic> _state = {
    'state': 'idle',
    'running': false,
    'homed': false,
    'travelMm': 150.0,
    'speed': 0,
    'stroke': 40,
    'depth': 60,
    'sensation': 50,
    'pattern': 0,
    'strategy': 0,
    'positionMm': 0.0,
    'voltage': 24.0,
    'temp': 30.0,
    'current': 0.2,
    'fault': 0,
    'online': true,
    'gain': 1.0,
  };
  Timer? _timer, _home;
  bool _connected = false;
  @override
  bool get demo => true;
  @override
  bool get connected => _connected;
  @override
  bool get connecting => false;
  @override
  bool get scanning => false;
  @override
  bool get hasLease => _connected;
  @override
  String get name => '离线演示';
  @override
  String get firmware => '模拟设备';
  @override
  String? get error => null;
  @override
  List<NearbyDevice> get devices => [];
  @override
  Stream<Map<String, dynamic>> get states => _states.stream;
  void _emit() {
    if (_connected) _states.add(Map.of(_state));
  }

  @override
  Future<void> scan() async {}
  @override
  Future<void> connect(String id) async {
    _connected = true;
    _state['running'] = false;
    _state['homed'] = false;
    _state['state'] = 'idle';
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _emit());
    notifyListeners();
    _emit();
  }

  @override
  Future<Map<String, dynamic>> request(
    String op, {
    Map<String, dynamic> args = const {},
    String? path,
    bool urgent = false,
  }) async {
    if (op == 'setting.read') return {'value': _state['travelMm']};
    if (op == 'setting.write') _state['travelMm'] = args['value'];
    if (op == 'session.apply') {
      _state.addAll(args);
      _state['state'] = _state['running'] == true ? 'running' : 'ready';
    }
    if (op == 'ossm.command') {
      switch (args['command']) {
        case 'go:home':
          _state['state'] = 'homing';
          _state['homed'] = false;
          _home = Timer(const Duration(seconds: 2), () {
            _state['homed'] = true;
            _state['positionMm'] = 0.0;
            _state['state'] = 'ready';
            _emit();
          });
        case 'go:estop':
        case 'go:softEnd':
          _home?.cancel();
          _state['running'] = false;
          _state['state'] = 'ready';
          // Firmware holds position wherever the stroke stopped.
          final travel = (_state['travelMm'] as num).toDouble();
          final depth = (_state['depth'] as num) / 100 * travel;
          final stroke = (_state['stroke'] as num) / 100 * travel;
          _state['positionMm'] = depth - stroke / 2;
        case 'go:clearFault':
          _state['fault'] = 0;
      }
    }
    _emit();
    return {};
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _timer?.cancel();
    _home?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _home?.cancel();
    unawaited(_states.close());
    super.dispose();
  }
}
