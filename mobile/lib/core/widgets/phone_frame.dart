import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';
import 'app_icon.dart';

/// Tells descendants whether they are rendered inside the drawn phone frame,
/// e.g. so a footer can paint the home indicator itself.
class FrameScope extends InheritedWidget {
  const FrameScope({super.key, required this.isFramed, required super.child});

  final bool isFramed;

  static bool isFramedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FrameScope>()?.isFramed ?? false;

  @override
  bool updateShouldNotify(FrameScope oldWidget) => isFramed != oldWidget.isFramed;
}

/// Optional 390×844 iPhone frame from the design spec (bezel 11, radius 54/44,
/// Dynamic Island, 9:41 status bar). Enabled with --dart-define=FRAME=true.
/// When disabled, the app runs full-screen with the device's own status bar.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  static const _outer = Size(390, 844);
  static const _bezel = 11.0;
  static const _statusBarHeight = 54.0;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return FrameScope(isFramed: false, child: child);

    final inner = Size(_outer.width - _bezel * 2, _outer.height - _bezel * 2);
    final media = MediaQuery.of(context);

    return ColoredBox(
      color: const Color(0xFFE9ECF2),
      child: Center(
        child: FittedBox(
          child: SizedBox.fromSize(
            size: _outer,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bezel,
                borderRadius: BorderRadius.circular(54),
                boxShadow: AppShadows.bezel,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(_bezel),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(44),
                      child: MediaQuery(
                        data: media.copyWith(
                          size: inner,
                          padding: const EdgeInsets.only(top: _statusBarHeight),
                          viewPadding: const EdgeInsets.only(top: _statusBarHeight),
                        ),
                        child: FrameScope(
                          isFramed: true,
                          child: Stack(
                            children: [
                              Positioned.fill(child: child),
                              const _StatusBar(),
                              const _DynamicIsland(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bezel inner line: inset 0 0 0 1 rgba(255,255,255,.12)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(54),
                          border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: 54,
        child: Stack(
          children: [
            Positioned(
              left: 24,
              top: 16,
              width: 100,
              child: Text('9:41', textAlign: TextAlign.center, style: AppTextStyles.statusTime),
            ),
            const Positioned(
              right: 24,
              top: 16,
              child: AppIcon(AppIcons.levels, width: 100, height: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _DynamicIsland extends StatelessWidget {
  const _DynamicIsland();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 11,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 126,
            height: 37,
            padding: const EdgeInsets.only(right: 14),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: AppColors.island,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.islandLens,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.islandRing, width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom area under a sticky footer: in frame mode the 30px home indicator
/// (pill 135×5, #B9C0C9, bottom 8); on a real device the system safe area.
class BottomInset extends StatelessWidget {
  const BottomInset({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FrameScope.isFramedOf(context)) {
      final systemInset = MediaQuery.paddingOf(context).bottom;
      return SizedBox(height: systemInset > 16 ? systemInset : 16);
    }
    return SizedBox(
      height: 30,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 135,
          height: 5,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.homePill,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
