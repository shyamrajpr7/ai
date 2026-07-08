import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/hive_service.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/canvas_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/agent_provider.dart';
import 'providers/prompt_vault_provider.dart';
import 'providers/knowledge_graph_provider.dart';
import 'providers/code_studio_provider.dart';
import 'providers/ritual_provider.dart';
import 'providers/chat_export_provider.dart';
import 'providers/context_weaver_provider.dart';
import 'providers/document_oracle_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/language_dojo_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  final hiveService = HiveService();
  await hiveService.init();

  final settingsProvider = SettingsProvider(hiveService);
  await settingsProvider.load();

  final knowledgeGraphProvider = KnowledgeGraphProvider(hiveService);
  await knowledgeGraphProvider.load();

  final contextWeaverProvider = ContextWeaverProvider(hiveService);
  await contextWeaverProvider.load();

  final chatProvider = ChatProvider(hiveService, settingsProvider, knowledgeGraphProvider, contextWeaverProvider: contextWeaverProvider);
  await chatProvider.load();

  final canvasProvider = CanvasProvider(hiveService);
  await canvasProvider.load();

  final moodProvider = MoodProvider(hiveService, settingsProvider);
  await moodProvider.load();

  final agentProvider = AgentProvider(settingsProvider);

  final promptVaultProvider = PromptVaultProvider(hiveService);
  await promptVaultProvider.load();

  final codeStudioProvider = CodeStudioProvider(chatProvider);

  final ritualProvider = RitualProvider(hiveService, chatProvider);
  await ritualProvider.load();

  final chatExportProvider = ChatExportProvider(chatProvider);

  final documentOracleProvider = DocumentOracleProvider(settingsProvider);

  final habitProvider = HabitProvider(hiveService, settingsProvider);
  await habitProvider.load();

  final languageDojoProvider = LanguageDojoProvider(settingsProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: chatProvider),
        ChangeNotifierProvider.value(value: canvasProvider),
        ChangeNotifierProvider.value(value: moodProvider),
        ChangeNotifierProvider.value(value: agentProvider),
        ChangeNotifierProvider.value(value: promptVaultProvider),
        ChangeNotifierProvider.value(value: knowledgeGraphProvider),
        ChangeNotifierProvider.value(value: codeStudioProvider),
        ChangeNotifierProvider.value(value: ritualProvider),
        ChangeNotifierProvider.value(value: chatExportProvider),
        ChangeNotifierProvider.value(value: contextWeaverProvider),
        ChangeNotifierProvider.value(value: documentOracleProvider),
        ChangeNotifierProvider.value(value: habitProvider),
        ChangeNotifierProvider.value(value: languageDojoProvider),
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
    final surfaceDark = const Color(0xFF0A0A0F);
    final surfaceCard = const Color(0xFF12121A);
    final surfaceElevated = const Color(0xFF1A1A2E);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfaceDark,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: const Color(0xFF448AFF),
        surface: surfaceDark,
        error: const Color(0xFFEF5350),
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surfaceDark,
        shape: const RoundedRectangleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'SpaceGrotesk',
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent.withOpacity(0.5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withOpacity(0.3),
        selectionHandleColor: accent,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.06),
        thickness: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceElevated.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
