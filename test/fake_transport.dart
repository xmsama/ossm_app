import 'dart:async';

import 'package:ossm_app/ble/device_transport.dart';

class FakeTransport extends DeviceTransport {
  final updates = StreamController<Map<String, dynamic>>.broadcast(sync: true);
  final List<Map<String, dynamic>> commands = [];
  bool linked = false;
  bool failWrites = false;
  Completer<Map<String, dynamic>>? startGate;
  @override
  bool get connected => linked;
  @override
  bool get scanning => false;
  @override
  bool get connecting => false;
  @override
  bool get hasLease => linked;
  @override
  String get name => 'Test OSSM';
  @override
  String get firmware => '0.3.1';
  @override
  String? get error => null;
  @override
  List<NearbyDevice> get devices => [];
  @override
  Stream<Map<String, dynamic>> get states => updates.stream;
  @override
  Future<void> scan() async {}
  @override
  Future<void> connect(String id) async {
    linked = true;
    notifyListeners();
  }

  @override
  Future<void> disconnect() async {
    linked = false;
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>> request(
    String op, {
    Map<String, dynamic> args = const {},
    String? path,
    bool urgent = false,
  }) async {
    commands.add({'op': op, 'args': args, 'path': path, 'urgent': urgent});
    if (failWrites && op != 'setting.read') throw StateError('write failed');
    if (op == 'setting.read') return {'value': 150};
    if (args['running'] == true && startGate != null) return startGate!.future;
    return {};
  }

  void state([Map<String, dynamic> overrides = const {}]) => updates.add({
    'state': 'ready',
    'running': false,
    'online': true,
    'fault': 0,
    'speed': 20,
    'stroke': 40,
    'depth': 60,
    'sensation': 50,
    'pattern': 0,
    'homed': true,
    'travelMm': 150,
    'voltage': 24.1,
    'temp': 32,
    ...overrides,
  });
  @override
  void dispose() {
    unawaited(updates.close());
    super.dispose();
  }
}
