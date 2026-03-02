import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/app_strings.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() {
  runApp(const SenseIAApp());
}

/// Application principale SenseIA
class SenseIAApp extends StatefulWidget {
  const SenseIAApp({super.key});

  @override
  State<SenseIAApp> createState() => _SenseIAAppState();
}

class _SenseIAAppState extends State<SenseIAApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeProvider,
      builder: (context, child) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeProvider.themeMode,
          home: HomePage(themeProvider: _themeProvider),
        );
      },
    );
  }
}
