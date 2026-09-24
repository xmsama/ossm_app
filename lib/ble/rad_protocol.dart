import 'dart:convert';

class RadProtocol {
  static const service = '522b443a-4f53-534d-0001-420badbabe69';
  // rad-ble characteristicUuid(): replace bytes 19..22, NOT the tail.
  static String characteristic(String suffix) =>
      '${service.substring(0, 19)}$suffix${service.substring(23)}';

  static Map<String, dynamic> decode(List<int> bytes) {
    final value = jsonDecode(utf8.decode(bytes));
    if (value is! Map<String, dynamic>) {
      throw const FormatException('设备数据不是 JSON 对象');
    }
    return value;
  }

  static List<int> encode(
    int id,
    String op, {
    Map<String, dynamic> args = const {},
    String? path,
    int? lease,
  }) {
    final bytes = utf8.encode(
      jsonEncode({
        'v': 1,
        'id': id,
        'op': op,
        'path': ?path,
        'args': args,
        'lease': ?lease,
      }),
    );
    if (bytes.length > 509) throw const FormatException('命令超出协议长度');
    return bytes;
  }
}

class DeviceException implements Exception {
  const DeviceException(this.message);
  final String message;
  @override
  String toString() => message;
}
