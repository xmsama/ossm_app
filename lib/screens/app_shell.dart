import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/session_controller.dart';
import '../theme/palette.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/run_dock.dart';
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
              center: Alignment(0, -0.6),
              radius: 1.1,
              colors: [Color(0xFF221830), OssmPalette.bg],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IndexedStack(
                        index: _index,
                        children: [
                          ControlScreen(session: widget.session),
                          DeviceScreen(session: widget.session),
                          ProfileScreen(session: widget.session),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 6,
                      child: _Toast(session: widget.session),
                    ),
                  ],
                ),
              ),
              ListenableBuilder(
                listenable: widget.session,
                builder: (context, _) => RunDock(
                  session: widget.session,
                  onOpenDevice: () => setState(() => _index = 1),
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

/// Transient device feedback floating above the dock.
class _Toast extends StatelessWidget {
  const _Toast({required this.session});
  final SessionController session;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final text = session.message;
      return IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, .3),
                end: Offset.zero,
              ).animate(a),
              child: child,
            ),
          ),
          child: text == null
              ? const SizedBox.shrink()
              : Center(
                  key: ValueKey(text),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: OssmPalette.surfaceHi.withValues(alpha: .96),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: .08)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66000000), blurRadius: 16),
                      ],
                    ),
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: OssmPalette.text,
                      ),
                    ),
                  ),
                ),
        ),
      );
    },
  );
}
