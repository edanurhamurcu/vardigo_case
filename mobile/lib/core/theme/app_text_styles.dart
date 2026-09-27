import 'dart:ui' show FontFeature;

import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Typography tokens (Urbanist, liga/calt off). Line heights are given in px in
/// the spec, so `height = lineHeight / fontSize`.
abstract final class AppTextStyles {
  static const fontFamily = 'Urbanist';

  static const _features = [FontFeature.disable('liga'), FontFeature.disable('calt')];

  static TextStyle _style(
    double size,
    FontWeight weight,
    double lineHeight, {
    double tracking = 0,
    Color color = AppColors.strong,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: lineHeight / size,
      letterSpacing: tracking,
      color: color,
      fontFeatures: _features,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// 9:41
  static final statusTime = _style(17, FontWeight.w700, 22, tracking: -0.3);

  /// "Görüşme Talepleri"
  static final title20 = _style(20, FontWeight.w600, 28, color: AppColors.slate700);

  /// Person name, job title
  static final title18 = _style(18, FontWeight.w500, 24, tracking: -0.27, color: AppColors.slate700);

  /// Pay amount on offer card
  static final pay18 = _style(18, FontWeight.w600, 24, tracking: -0.27, color: AppColors.green);

  /// "Eşleşen Personeller"
  static final title16Medium =
      _style(16, FontWeight.w500, 24, tracking: -0.176, color: AppColors.slate700);

  /// "N kişi seçildi"
  static final title16Semi = _style(16, FontWeight.w600, 24, tracking: -0.176, color: AppColors.primary);

  /// "26 personel bulundu" (slate-500 @ 80%)
  static final caption13 = _style(
    13,
    FontWeight.w400,
    20,
    tracking: -0.078,
    color: AppColors.slate500.withValues(alpha: 0.8),
  );

  /// Rating, attendance, km, district, date
  static final caption12Medium = _style(12, FontWeight.w500, 16, color: AppColors.slate700);

  /// Business name
  static final caption12 = _style(12, FontWeight.w400, 16, color: AppColors.gray500);

  /// Countdown bold part
  static final caption12Bold = _style(12, FontWeight.w700, 16);

  /// Segmented tab label (Eşleşen Personeller)
  static final tab12 = _style(12, FontWeight.w500, 16, color: AppColors.slate500);

  /// 3-way tab label (Görüşme Talepleri)
  static final tab13 = _style(13, FontWeight.w500, 20, tracking: -0.084, color: AppColors.soft);

  /// Buttons, sort chip
  static final label14 = _style(14, FontWeight.w500, 20, tracking: -0.084, color: AppColors.white);

  /// Empty states, detail text
  static final body14 = _style(14, FontWeight.w400, 20, color: AppColors.sub);
}
