import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ossm_app/screens/app_shell.dart';
import 'package:ossm_app/state/session_controller.dart';
import 'package:ossm_app/theme/ossm_theme.dart';

import '../test/fake_transport.dart';

class ReviewTransport extends FakeTransport {
  @override
  bool get demo => true;
  @override
  String get name => '演示设备';
}

void main() {
  testWidgets('render review screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.runAsync(() async {
      final font = FontLoader('OssmSans');
      font.addFont(
        File('assets/fonts/NotoSansSC.ttf')
            .readAsBytes()
            .then((v) => ByteData.sublistView(v)),
      );
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        File(
          'H:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes().then((v) => ByteData.sublistView(v)),
      );
      await icons.load();
    });
    final t = ReviewTransport();
    final s = SessionController(transport: t, persist: false);
    final key = GlobalKey();
    final theme = OssmTheme.dark();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: AppShell(session: s),
        ),
      ),
    );
    await s.connect('test');
    t.state();
    await tester.pumpAndSettle();
    for (final entry in {
      '控制': 'control',
      '设备': 'device',
      '我的': 'profile',
    }.entries) {
      await tester.tap(find.text(entry.key).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/${entry.value}-preview.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
    s.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
