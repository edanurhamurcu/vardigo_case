import 'package:flutter/painting.dart';

/// Shadow tokens from the spec. CSS "x y blur rgba" maps to BoxShadow(offset, blurRadius).
abstract final class AppShadows {
  static const card = [
    BoxShadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x0A243D82)), // rgba(36,61,130,.04)
  ];

  /// The 4px inset left strip of the selected card is drawn separately (Flutter has no inset shadow).
  static const cardSelected = [
    BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x0A243D82)),
  ];

  static const squareButton = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x140A0D14)), // rgba(10,13,20,.08)
  ];

  static const sortChip = [
    BoxShadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x0A000000)), // rgba(0,0,0,.04)
  ];

  /// Active pill — Eşleşen Personeller
  static const tabActiveMatch = [
    BoxShadow(offset: Offset(0, 6), blurRadius: 5, color: Color(0x0F0E121B)), // rgba(14,18,27,.06)
    BoxShadow(offset: Offset(0, 2), blurRadius: 2, color: Color(0x080E121B)), // rgba(14,18,27,.03)
  ];

  /// Active pill — Görüşme Talepleri
  static const tabActiveOffers = [
    BoxShadow(offset: Offset(0, 6), blurRadius: 10, color: Color(0x0F0E121B)),
    BoxShadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x080E121B)),
  ];

  static const bezel = [
    BoxShadow(offset: Offset(0, 28), blurRadius: 48, color: Color(0x380F121B)), // rgba(15,18,27,.22)
  ];
}
