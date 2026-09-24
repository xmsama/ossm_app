import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ossm_app/screens/app_shell.dart';
import 'package:ossm_app/state/session_controller.dart';
import 'package:ossm_app/theme/ossm_theme.dart';

import 'fake_transport.dart';

void main() {
  for (final size in [const Size(360, 800), const Size(320, 568)]) {
    testWidgets('all screens fit $size and emergency stop stays visible', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final t = FakeTransport();
      final s = SessionController(transport: t, persist: false);
      await tester.pumpWidget(
        MaterialApp(
          theme: OssmTheme.dark(),
          home: AppShell(session: s),
        ),
      );
      await tester.pump();
      expect(find.text('紧急停止'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final tab in ['设备', '我的', '控制']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('紧急停止').hitTestable(), findsOneWidget);
      }
      await s.connect('test');
      t.state();
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    });
  }
}
