import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import 'app_icon.dart';

/// 56×56 circular person photo with the optional online badge (bottom-right, ~24).
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.url, required this.online, this.size = 56});

  final String url;
  final bool online;
  final double size;

  @override
  Widget build(BuildContext context) {
    final badge = size * 0.42;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Decode at display size instead of full resolution.
              cacheWidth: (size * dpr).round(),
              errorBuilder: (_, _, _) => _Placeholder(size: size),
              frameBuilder: (_, child, frame, wasSync) =>
                  wasSync || frame != null ? child : _Placeholder(size: size),
            ),
          ),
          if (online)
            Positioned(
              right: -badge * 0.18,
              bottom: -badge * 0.18,
              child: AppIcon(AppIcons.online, size: badge),
            ),
        ],
      ),
    );
  }
}

/// 56×56 circular business logo served as SVG by the backend.
class LogoAvatar extends StatelessWidget {
  const LogoAvatar({super.key, required this.url, this.size = 56});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SvgPicture.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _Placeholder(size: size),
        errorBuilder: (_, _, _) => _Placeholder(size: size),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.slate100, shape: BoxShape.circle),
    );
  }
}
