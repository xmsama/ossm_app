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
                    ProfileScreen(session: widget.session),
                  ],
                ),
              ),
              ListenableBuilder(
                listenable: widget.session,
                builder: (context, _) => Column(
                  children: [
                    if (widget.session.demo)
                      const Text(
                        '离线演示 · 不连接真实设备',
                        style: TextStyle(
                          color: OssmPalette.warning,
                          fontSize: 12,
                        ),
                      ),
                    if (widget.session.message != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: Text(
                          widget.session.message!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: OssmPalette.textMuted,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6B7D),
                            side: const BorderSide(color: Color(0xFF81364D)),
                          ),
                          onPressed: widget.session.connected
                              ? widget.session.emergencyStop
                              : null,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('紧急停止'),
                        ),
                      ),
                    ),
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
