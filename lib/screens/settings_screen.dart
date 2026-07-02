import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white.withOpacity(0.6),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              'Appearance',
              Icons.palette_outlined,
              accent,
              children: [
                _buildLabel('Accent Color'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: _accentColors.map((color) {
                    final isSelected = color.value == accent.value;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        settings.setAccentColor(color);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.15),
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(isSelected ? 0.5 : 0.15),
                              blurRadius: isSelected ? 14 : 6,
                              spreadRadius: isSelected ? 2 : 0,
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'AI Backend',
              Icons.memory_outlined,
              accent,
              children: [
                _buildLabel('Provider'),
                const SizedBox(height: 8),
                _buildToggle(settings),
                const SizedBox(height: 16),
                if (settings.backend == BackendType.groq) ...[
                  _buildLabel('Model'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    initialValue: settings.groqModel,
                    hint: 'llama-3.1-8b-instant',
                    onChanged: (v) => settings.setGroqModel(v),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoBox(accent,
                    'Set your Groq API key in the .env file.',
                  ),
                ] else ...[
                  _buildLabel('Endpoint URL'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    initialValue: settings.ollamaEndpoint,
                    hint: 'http://localhost:11434/v1',
                    onChanged: (v) => settings.setOllamaEndpoint(v),
                  ),
                  const SizedBox(height: 12),
                  _buildLabel('Model'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    initialValue: settings.ollamaModel,
                    hint: 'llama3.2',
                    onChanged: (v) => settings.setOllamaModel(v),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
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
                          _buildLabel('Search the web'),
                          const SizedBox(height: 2),
                          Text(
                            'Pulls live search results as context',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: settings.webSearchEnabled,
                      onChanged: (v) => settings.setWebSearchEnabled(v),
                      activeColor: accent,
                      activeTrackColor: accent.withOpacity(0.3),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                        color: Colors.red.shade300.withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Nexus AI v1.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color accent, {
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.15),
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 13,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildToggle(SettingsProvider settings) {
    final accent = settings.accentColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleOption(
              label: 'Groq',
              icon: Icons.bolt_outlined,
              isSelected: settings.backend == BackendType.groq,
              accent: accent,
              onTap: () => settings.setBackend(BackendType.groq),
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withOpacity(0.08),
          ),
          Expanded(
            child: _toggleOption(
              label: 'Ollama',
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
    required IconData icon,
    required bool isSelected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? accent : Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.4),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Inter',
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(Color accent, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: accent.withOpacity(0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Clear History',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
        content: Text(
          'This will permanently delete all conversations. Continue?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              final provider = context.read<ChatProvider>();
              final ids = provider.conversations.map((c) => c.id).toList();
              for (final id in ids) {
                provider.deleteConversation(id);
              }
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
