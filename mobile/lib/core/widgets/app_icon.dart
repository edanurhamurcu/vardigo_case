import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icons shipped in assets/icons (from the case package — not redrawn).
enum AppIcons {
  alarm,
  back,
  check,
  close,
  date,
  eye,
  help,
  levels,
  money,
  online,
  pin,
  send,
  shield,
  sort,
  star;

  String get assetPath => 'assets/icons/$name.svg';
}

/// Renders an SVG icon. Most icons already carry the reference color;
/// pass [color] only for mask-style icons that must be tinted (star, eye, close…).
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = 20, this.width, this.height, this.color});

  final AppIcons icon;
  final double size;
  final double? width;
  final double? height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color;
    return SvgPicture.asset(
      icon.assetPath,
      width: width ?? size,
      height: height ?? size,
      colorFilter: tint == null ? null : ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
