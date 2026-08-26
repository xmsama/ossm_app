import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/app_shell.dart';
import 'state/session_controller.dart';
import 'theme/ossm_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  runApp(const OssmApp());
}

class OssmApp extends StatefulWidget {
  const OssmApp({super.key});

  @override
  State<OssmApp> createState() => _OssmAppState();
}

class _OssmAppState extends State<OssmApp> {
  final SessionController _session = SessionController();

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSSM',
      debugShowCheckedModeBanner: false,
      theme: OssmTheme.dark(),
      home: AppShell(session: _session),
    );
  }
}
