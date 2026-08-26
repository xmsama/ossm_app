import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/session_controller.dart';
import '../theme/palette.dart';
import '../widgets/bottom_nav.dart';
import 'control_screen.dart';
import 'device_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.session});

  final SessionController session;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: OssmPalette.bg,
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.45),
              radius: 1.05,
              colors: [Color(0xFF1A0D2C), OssmPalette.bg],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: [
                    ControlScreen(session: widget.session),
                    DeviceScreen(session: widget.session),
                    const ProfileScreen(),
                  ],
                ),
              ),
              BottomNav(
                index: _index,
                onChanged: (i) => setState(() => _index = i),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
