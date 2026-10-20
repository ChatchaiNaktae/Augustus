import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_menu_screen.dart';
import 'theme/retro_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set landscape orientation for optimal retro gaming experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Immersive full-screen mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const IWBTGApp());
}

class IWBTGApp extends StatelessWidget {
  const IWBTGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Augustus Brutal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: RetroTheme.background,
        fontFamily: 'monospace',
        colorScheme: const ColorScheme.dark(
          primary: RetroTheme.primary,
          secondary: RetroTheme.accent,
          surface: RetroTheme.surface,
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}
