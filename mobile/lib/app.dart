import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/phone_frame.dart';
import 'features/home/role_select_screen.dart';

class VardigoApp extends StatelessWidget {
  const VardigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VardiGO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // The frame wraps the Navigator so every route renders inside the bezel.
      builder: (context, child) => PhoneFrame(
        enabled: AppConfig.showPhoneFrame,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const RoleSelectScreen(),
    );
  }
}
