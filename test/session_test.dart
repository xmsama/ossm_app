import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ossm_app/ble/rad_protocol.dart';
import 'package:ossm_app/state/session_controller.dart';
import 'package:ossm_app/models/stroke_pattern.dart';

import 'fake_transport.dart';

void main() {
  test('UUID replaces the fourth UUID group and JSON preserves lease', () {
    expect(
      RadProtocol.characteristic('1000'),
      '522b443a-4f53-534d-1000-420badbabe69',
    );
    expect(
      RadProtocol.characteristic('2000'),
      '522b443a-4f53-534d-2000-420badbabe69',
    );
    final data = RadProtocol.decode(
      RadProtocol.encode(
        7,
        'session.apply',
        lease: 4294967295,
        args: {'running': true},
      ),
    );
    expect(data['lease'], 4294967295);
    expect(data['id'], 7);
    expect(data['args']['running'], true);
    expect(() => RadProtocol.decode([123]), throwsFormatException);
    expect(StrokePattern.catalog[4].id, PatternId.deeper);
    expect(StrokePattern.catalog[5].id, PatternId.stopGo);
    expect(StrokePattern.catalog[6].id, PatternId.insist);
  });

  testWidgets('first launch, homing, state-confirmed start and stop', (
    tester,
  ) async {
    final transport = FakeTransport();
    final session = SessionController(transport: transport, persist: false);
    expect(session.connected, false);
    expect(session.homed, false);
    expect(session.travelMm, 0);
    await session.toggleRun();
    expect(transport.commands, isEmpty);
    await session.connect('test');
    transport.state({'homed': false, 'state': 'idle'});
    expect(session.canStart, false);
    await session.home();
    expect(session.homed, false);
    transport.state({'homed': false, 'state': 'homing'});
    expect(session.canStart, false);
    transport.state();
    expect(session.canStart, true);
    await session.toggleRun();
    expect(session.running, false, reason: 'ACK is not motor telemetry');
    expect(
      session.canStart,
      false,
      reason: 'Do not allow repeated starts while awaiting telemetry',
    );
    transport.state({'running': true, 'state': 'running'});
    expect(session.running, true);
    await session.emergencyStop();
    expect(transport.commands.last['args']['command'], 'go:estop');
    expect(transport.commands.last['urgent'], true);
    transport.state();
    expect(session.running, false);
    session.dispose();
  });

  testWidgets(
    'drag edits coalesce, obey speed limit and preserve stroke bounds',
    (tester) async {
      final t = FakeTransport();
      final s = SessionController(transport: t, persist: false);
      await s.connect('test');
      t.state();
      t.commands.clear();
      for (var i = 0; i < 30; i++) {
        s.nudgeSpeed(4);
        s.shiftDepth(-10);
      }
      s.setShallow(-100);
      s.setDeep(500);
      expect(s.speed, 40);
      expect(s.stroke <= s.depth, true);
      expect(s.shallow >= 0 && s.depth <= 100, true);
      await tester.pump(const Duration(milliseconds: 151));
      expect(t.commands.length, 1);
      expect(t.commands.single['args']['speed'], 40);
      expect(t.commands.single['args'].containsKey('running'), false);
      s.dispose();
    },
  );

  testWidgets(
    'stop drops pending debounced edits and late start cannot restore timer',
    (tester) async {
      final t = FakeTransport();
      final s = SessionController(transport: t, persist: false);
      await s.connect('test');
      t.state();
      t.commands.clear();
      s.nudgeSpeed(5);
      await s.emergencyStop();
      await tester.pump(const Duration(milliseconds: 200));
      expect(t.commands.length, 1);
      t.state();
      t.startGate = Completer<Map<String, dynamic>>();
      final starting = s.toggleRun();
      await tester.pump();
      await s.emergencyStop();
      t.startGate!.complete({});
      await starting;
      expect(s.remainingSeconds, null);
      expect(s.running, false);
      s.dispose();
    },
  );

  testWidgets(
    'fault, bus loss and disconnect lock start; reconnect does not resume',
    (tester) async {
      final t = FakeTransport();
      final s = SessionController(transport: t, persist: false);
      await s.connect('test');
      t.state({'fault': 2});
      expect(s.canStart, false);
      t.state({'online': false});
      expect(s.canStart, false);
      t.state();
      await s.disconnect();
      expect(s.homed, false);
      expect(s.travelMm, 0);
      await s.connect('test');
      expect(s.running, false);
      expect(s.canStart, false);
      s.dispose();
    },
  );

  testWidgets('stale or missing telemetry stops and disconnects', (
    tester,
  ) async {
    var now = DateTime(2026);
    final t = FakeTransport();
    final s = SessionController(transport: t, persist: false, now: () => now);
    await s.connect('test');
    t.state();
    now = now.add(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
    expect(t.commands.any((c) => c['args']['command'] == 'go:estop'), true);
    expect(s.connected, false);
    await s.connect('test');
    now = now.add(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
    expect(s.connected, false);
    s.dispose();
  });

  testWidgets(
    'timer expiry soft-stops; failed stop disconnects with actionable error',
    (tester) async {
      var now = DateTime(2026);
      final t = FakeTransport();
      final s = SessionController(transport: t, persist: false, now: () => now);
      await s.connect('test');
      t.state();
      s.timerMinutes = 1;
      await s.toggleRun();
      t.state({'running': true, 'state': 'running'});
      now = now.add(const Duration(minutes: 1));
      t.state({'running': true, 'state': 'running'});
      await tester.pump(const Duration(seconds: 1));
      expect(t.commands.last['args']['command'], 'go:softEnd');
      t.failWrites = true;
      await s.emergencyStop();
      expect(s.connected, false);
      expect(s.message, contains('实体急停'));
      s.dispose();
    },
  );

  testWidgets('preset loads parameters only, never starts motor', (
    tester,
  ) async {
    final t = FakeTransport();
    final s = SessionController(transport: t, persist: false);
    await s.connect('test');
    t.state();
    s.savePreset('轻柔');
    t.commands.clear();
    s.applyPreset(0);
    await tester.pump(const Duration(milliseconds: 151));
    expect(t.commands.single['args'].containsKey('running'), false);
    s.dispose();
  });
}
