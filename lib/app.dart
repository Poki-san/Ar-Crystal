import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/presentation/main_shell.dart';

class EchoWearApp extends StatelessWidget {
  const EchoWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECHO WEAR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}
