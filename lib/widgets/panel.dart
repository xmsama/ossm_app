import 'package:flutter/material.dart';

import '../state/session_controller.dart';
import '../theme/palette.dart';

/// Base surface for every grouped block in the app.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.tint,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  @override
  Widget build(BuildContext context) => Material(
    color: tint?.withValues(alpha: .10) ??
        OssmPalette.surface.withValues(alpha: .78),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(
        color: tint?.withValues(alpha: .35) ??
            Colors.white.withValues(alpha: .06),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

/// Small spaced label above an instrument or section.
class PanelLabel extends StatelessWidget {
  const PanelLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: OssmPalette.textDim,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

Color toneColor(DeviceTone tone) => switch (tone) {
  DeviceTone.off => OssmPalette.textDim,
  DeviceTone.waiting => OssmPalette.warning,
  DeviceTone.ready => OssmPalette.cyan,
  DeviceTone.live => OssmPalette.pink,
  DeviceTone.fault => OssmPalette.fault,
};

class StateChip extends StatelessWidget {
  const StateChip({super.key, required this.label, required this.tone});
  final String label;
  final DeviceTone tone;
  @override
  Widget build(BuildContext context) {
    final c = toneColor(tone);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c,
              boxShadow: [BoxShadow(color: c.withValues(alpha: .6), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c == OssmPalette.textDim ? OssmPalette.textMuted : c,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page title used by the secondary tabs.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, this.subtitle, {super.key, this.trailing});
  final String title, subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: OssmPalette.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: OssmPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
