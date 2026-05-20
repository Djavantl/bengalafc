import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'features/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeNotifier.loadTheme();
  runApp(const BengalaFCApp());
}

class BengalaFCApp extends StatelessWidget {
  const BengalaFCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'BengalaFC',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const HomePage(),
        );
      },
    );
  }
}
