import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../services/notification_service.dart';
import '../models/persona.dart';
import '../widgets/gradient_mesh_background.dart';

const _uuid = Uuid();

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
      });
    }
  }

  static const _accentColors = [
    Color(0xFF7C4DFF),
    Color(0xFF448AFF),
    Color(0xFF00BCD4),
    Color(0xFF00E676),
    Color(0xFFFF4081),
    Color(0xFFFF6D00),
    Color(0xFFE040FB),
    Color(0xFF536DFE),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accent = settings.accentColor;

    return GradientMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, const Color(0xFF448AFF)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.tune, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildSection(
              'Appearance',
              Icons.palette_outlined,
              accent,
              children: [
                _buildLabel('Accent Color'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _accentColors.map((color) {
                    final isSelected = color.value == accent.value;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        settings.setAccentColor(color);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.1),
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(isSelected ? 0.6 : 0.2),
                              blurRadius: isSelected ? 18 : 8,
                              spreadRadius: isSelected ? 2 : 0,
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show timestamps',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Display time under each message',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: settings.showTimestamps
                            ? accent.withOpacity(0.25)
                            : Colors.white.withOpacity(0.08),
                      ),
                      child: Switch(
                        value: settings.showTimestamps,
                        onChanged: (v) => settings.setShowTimestamps(v),
                        activeColor: accent,
                        activeTrackColor: accent.withOpacity(0.3),
                        inactiveThumbColor: Colors.white.withOpacity(0.3),
                        inactiveTrackColor: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildSection(
              'AI Backend',
              Icons.memory_outlined,
              accent,
              children: [
                _buildLabel('Provider'),
                const SizedBox(height: 10),
                _buildToggle(settings),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: settings.backend == BackendType.groq
                      ? _groqFields(settings, accent)
                      : settings.backend == BackendType.claude
                          ? _claudeFields(settings, accent)
                          : _ollamaFields(settings, accent),
                ),
                const SizedBox(height: 20),
                _buildTemperatureSlider(settings, accent),
              ],
            ),
            const SizedBox(height: 14),
            _buildSection(
              'Web Search',
              Icons.language_rounded,
              accent,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search the web',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Pulls live search results as context for the AI',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: settings.webSearchEnabled
                            ? accent.withOpacity(0.25)
                            : Colors.white.withOpacity(0.08),
                      ),
                      child: Switch(
                        value: settings.webSearchEnabled,
                        onChanged: (v) => settings.setWebSearchEnabled(v),
                        activeColor: accent,
                        activeTrackColor: accent.withOpacity(0.3),
                        inactiveThumbColor: Colors.white.withOpacity(0.3),
                        inactiveTrackColor: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildSection(
              'Daily Briefing',
              Icons.wb_sunny_outlined,
              accent,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Morning briefing notification',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Get a daily summary of habits, mood, and more',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: settings.briefingEnabled
                            ? accent.withOpacity(0.25)
                            : Colors.white.withOpacity(0.08),
                      ),
                      child: Switch(
                        value: settings.briefingEnabled,
                        onChanged: (v) async {
                          settings.setBriefingEnabled(v);
                          final notificationService = NotificationService();
                          await notificationService.init();
                          if (v) {
                            await notificationService.requestPermissions();
                            await notificationService.scheduleDailyBriefing(
                              hour: settings.briefingHour,
                              minute: settings.briefingMinute,
                            );
                          } else {
                            await notificationService.cancelDailyBriefing();
                          }
                        },
                        activeColor: accent,
                        activeTrackColor: accent.withOpacity(0.3),
                        inactiveThumbColor: Colors.white.withOpacity(0.3),
                        inactiveTrackColor: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
                if (settings.briefingEnabled) ...[
                  const SizedBox(height: 20),
                  _buildLabel('Notification Time'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: settings.briefingHour,
                          minute: settings.briefingMinute,
                        ),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: accent,
                                surface: const Color(0xFF1A1A2E),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        settings.setBriefingTime(picked.hour, picked.minute);
                        final notificationService = NotificationService();
                        await notificationService.init();
                        await notificationService.scheduleDailyBriefing(
                          hour: picked.hour,
                          minute: picked.minute,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: accent.withOpacity(0.7),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${settings.briefingHour.toString().padLeft(2, '0')}:${settings.briefingMinute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            _buildPersonaSection(context, settings, accent),
            const SizedBox(height: 14),
            _buildSection(
              'Data',
              Icons.storage_outlined,
              accent,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _clearHistory(context),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear All History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade300,
                      side: BorderSide(
                        color: Colors.red.shade300.withOpacity(0.25),
                      ),
                      backgroundColor: Colors.red.withOpacity(0.05),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accent.withOpacity(0.3), const Color(0xFF448AFF).withOpacity(0.2)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_awesome, size: 14, color: Colors.white24),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nexus AI',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Version $_appVersion',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.12),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _groqFields(SettingsProvider settings, Color accent) {
    return Column(
      key: const ValueKey('groq'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Model'),
        const SizedBox(height: 8),
        _buildInputField(
          initialValue: settings.groqModel,
          hint: 'llama-3.1-8b-instant',
          icon: Icons.smart_toy_outlined,
          onChanged: (v) => settings.setGroqModel(v),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withOpacity(0.12),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: accent.withOpacity(0.6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Set your Groq API key in the .env file.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ollamaFields(SettingsProvider settings, Color accent) {
    return Column(
      key: const ValueKey('ollama'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Endpoint URL'),
        const SizedBox(height: 8),
        _buildInputField(
          initialValue: settings.ollamaEndpoint,
          hint: 'http://localhost:11434/v1',
          icon: Icons.link_outlined,
          onChanged: (v) => settings.setOllamaEndpoint(v),
        ),
        const SizedBox(height: 16),
        _buildLabel('Model'),
        const SizedBox(height: 8),
        _buildInputField(
          initialValue: settings.ollamaModel,
          hint: 'llama3.2',
          icon: Icons.smart_toy_outlined,
          onChanged: (v) => settings.setOllamaModel(v),
        ),
      ],
    );
  }

  Widget _claudeFields(SettingsProvider settings, Color accent) {
    return Column(
      key: const ValueKey('claude'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Model'),
        const SizedBox(height: 8),
        _buildInputField(
          initialValue: settings.claudeModel,
          hint: 'claude-sonnet-4-20250514',
          icon: Icons.smart_toy_outlined,
          onChanged: (v) => settings.setClaudeModel(v),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withOpacity(0.12),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: accent.withOpacity(0.6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Set your Anthropic API key in the .env file.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureSlider(SettingsProvider settings, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Temperature'),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.ac_unit, size: 14, color: Colors.white.withOpacity(0.2)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  activeTrackColor: accent,
                  inactiveTrackColor: Colors.white.withOpacity(0.08),
                  thumbColor: accent,
                  overlayColor: accent.withOpacity(0.1),
                ),
                child: Slider(
                  value: settings.temperature,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: (v) => settings.setTemperature(v),
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                settings.temperature.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.whatshot, size: 14, color: Colors.white.withOpacity(0.3)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Lower = precise, Higher = creative',
          style: TextStyle(
            color: Colors.white.withOpacity(0.25),
            fontSize: 11,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color accent, {
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(0.2),
                          accent.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(icon, size: 18, color: accent.withOpacity(0.8)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaSection(BuildContext context, SettingsProvider settings, Color accent) {
    final personas = settings.personas;
    return _buildSection(
      'Personas',
      Icons.face_outlined,
      accent,
      children: [
        _buildLabel('Active Persona'),
        const SizedBox(height: 10),
        ...personas.map((p) {
          final isActive = p.id == settings.activePersona.id;
          return GestureDetector(
            onTap: () => settings.setActivePersona(p.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? accent.withOpacity(0.1)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? accent.withOpacity(0.3)
                      : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? p.color.withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                    ),
                    child: Center(
                      child: Text(
                        p.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.systemPrompt.length > 60
                              ? '${p.systemPrompt.substring(0, 57)}...'
                              : p.systemPrompt,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  if (!isActive)
                    GestureDetector(
                      onTap: () => _editPersona(context, settings, p),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _createPersona(context, settings),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Persona'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withOpacity(0.25)),
              backgroundColor: accent.withOpacity(0.05),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _createPersona(BuildContext context, SettingsProvider settings) {
    _showPersonaDialog(
      context,
      settings,
      title: 'Create Persona',
      onSave: (name, prompt, emoji) {
        final persona = Persona(
          id: _uuid.v4(),
          name: name,
          systemPrompt: prompt,
          emoji: emoji,
        );
        settings.addPersona(persona);
        settings.setActivePersona(persona.id);
      },
    );
  }

  void _editPersona(
      BuildContext context, SettingsProvider settings, Persona persona) {
    _showPersonaDialog(
      context,
      settings,
      title: 'Edit Persona',
      initialName: persona.name,
      initialPrompt: persona.systemPrompt,
      initialEmoji: persona.emoji,
      onSave: (name, prompt, emoji) {
        settings.updatePersona(persona.copyWith(
          name: name,
          systemPrompt: prompt,
          emoji: emoji,
        ));
      },
      onDelete: persona.id.startsWith('default-')
          ? null
          : () => settings.deletePersona(persona.id),
    );
  }

  void _showPersonaDialog(
    BuildContext context,
    SettingsProvider settings, {
    required String title,
    String initialName = '',
    String initialPrompt = '',
    String initialEmoji = '🤖',
    required void Function(String name, String prompt, String emoji) onSave,
    VoidCallback? onDelete,
  }) {
    final nameController = TextEditingController(text: initialName);
    final promptController = TextEditingController(text: initialPrompt);
    final emojiController = TextEditingController(text: initialEmoji);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: settings.accentColor.withOpacity(0.15),
              ),
              child: Center(
                child: Text(initialEmoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(
              controller: nameController,
              label: 'Name',
              hint: 'e.g. Code Wizard',
            ),
            const SizedBox(height: 14),
            _buildDialogField(
              controller: promptController,
              label: 'System Prompt',
              hint: 'e.g. You are an expert...',
              maxLines: 4,
            ),
            const SizedBox(height: 14),
            _buildDialogField(
              controller: emojiController,
              label: 'Emoji',
              hint: 'e.g. 🧙',
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        actions: [
          if (onDelete != null)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onDelete();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade300,
              ),
              child: const Text('Delete'),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.5),
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty &&
                  promptController.text.trim().isNotEmpty) {
                onSave(
                  nameController.text.trim(),
                  promptController.text.trim(),
                  emojiController.text.trim().isNotEmpty
                      ? emojiController.text.trim()
                      : '🤖',
                );
                Navigator.pop(ctx);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: settings.accentColor,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 12,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildToggle(SettingsProvider settings) {
    final accent = settings.accentColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
          children: [
            Expanded(
              child: _toggleOption(
                label: 'Groq Cloud',
                subtitle: 'Fast API',
                icon: Icons.bolt_outlined,
                isSelected: settings.backend == BackendType.groq,
                accent: accent,
                onTap: () => settings.setBackend(BackendType.groq),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _toggleOption(
                label: 'Claude',
                subtitle: 'Anthropic',
                icon: Icons.psychology_outlined,
                isSelected: settings.backend == BackendType.claude,
                accent: accent,
                onTap: () => settings.setBackend(BackendType.claude),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _toggleOption(
                label: 'Ollama',
                subtitle: 'Local',
                icon: Icons.computer_outlined,
                isSelected: settings.backend == BackendType.ollama,
                accent: accent,
                onTap: () => settings.setBackend(BackendType.ollama),
              ),
            ),
          ],
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent.withOpacity(0.2) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? accent : Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.45),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? accent.withOpacity(0.6)
                    : Colors.white.withOpacity(0.2),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String initialValue,
    required String hint,
    required ValueChanged<String> onChanged,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: TextField(
        controller: TextEditingController(text: initialValue),
        onChanged: onChanged,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.2),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: icon != null ? 42 : 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  void _clearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.15),
              ),
              child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text(
              'Clear History',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'This will permanently delete all conversations. This action cannot be undone.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                final provider = context.read<ChatProvider>();
                final ids = provider.conversations.map((c) => c.id).toList();
                for (final id in ids) {
                  provider.deleteConversation(id);
                }
                Navigator.pop(ctx);
                HapticFeedback.mediumImpact();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Delete Everything',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
