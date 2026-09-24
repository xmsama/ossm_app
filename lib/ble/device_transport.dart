import 'package:flutter/foundation.dart';

class NearbyDevice {
  const NearbyDevice(this.id, this.name, this.rssi);
  final String id;
  final String name;
  final int rssi;
}

abstract class DeviceTransport extends ChangeNotifier {
  bool get connected;
  bool get scanning;
  bool get connecting;
  bool get hasLease;
  bool get demo => false;
  String get name;
  String get firmware;
  String? get error;
  List<NearbyDevice> get devices;
  Stream<Map<String, dynamic>> get states;
  Future<void> scan();
  Future<void> connect(String id);
  Future<void> disconnect();
  Future<Map<String, dynamic>> request(
    String op, {
    Map<String, dynamic> args = const {},
    String? path,
    bool urgent = false,
  });
}
