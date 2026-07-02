import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/hive_service.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  final hiveService = HiveService();
  await hiveService.init();

  final settingsProvider = SettingsProvider(hiveService);
  await settingsProvider.load();

  final chatProvider = ChatProvider(hiveService, settingsProvider);
  await chatProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: chatProvider),
      ],
      child: const NexusApp(),
    ),
  );
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Nexus AI',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(settings.accentColor),
          home: const SplashScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: const Color(0xFF448AFF),
        surface: const Color(0xFF0A0A0F),
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF0A0A0F),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: accent.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withOpacity(0.3),
        selectionHandleColor: accent,
      ),
    );
  }
}
