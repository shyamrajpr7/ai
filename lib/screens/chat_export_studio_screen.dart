import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_export_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class ChatExportStudioScreen extends StatefulWidget {
  const ChatExportStudioScreen({super.key});

  @override
  State<ChatExportStudioScreen> createState() => _ChatExportStudioScreenState();
}

class _ChatExportStudioScreenState extends State<ChatExportStudioScreen> {
  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      body: GradientMeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(accent),
              Expanded(
                child: Consumer<ChatExportProvider>(
                  builder: (context, provider, _) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        _buildConversationPicker(accent, provider),
                        const SizedBox(height: 16),
                        _buildFormatSelector(accent, provider),
                        const SizedBox(height: 16),
                        _buildThemePicker(accent, provider),
                        const SizedBox(height: 16),
                        _buildPreview(accent, provider),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white.withOpacity(0.6),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.7)],
                  ),
                ),
                child: const Icon(Icons.file_download_rounded,
                    size: 15, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'Export Studio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const Spacer(),
              Consumer<ChatExportProvider>(
                builder: (context, provider, _) {
                  if (provider.previewContent.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return GestureDetector(
                    onTap: () {
                      provider.copyToClipboard();
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Copied to clipboard!'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: accent.withOpacity(0.8),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Copy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationPicker(Color accent, ChatExportProvider provider) {
    final convs = provider.conversations;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 16, color: accent.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                'Select Conversation',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: provider.selectedConversation?.id,
            dropdownColor: const Color(0xFF1A1A2E),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: 'Choose a conversation...',
              hintStyle:
                  TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            icon: Icon(Icons.expand_more_rounded,
                color: accent.withOpacity(0.6)),
            items: convs.map((c) {
              return DropdownMenuItem(
                value: c.id,
                child: Text(
                  c.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (id) {
              final conv = id != null
                  ? convs.firstWhere((c) => c.id == id)
                  : null;
              provider.selectConversation(conv);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector(Color accent, ChatExportProvider provider) {
    final formats = [
      {'key': 'markdown', 'label': 'Markdown', 'icon': Icons.description_rounded},
      {'key': 'html', 'label': 'HTML', 'icon': Icons.code_rounded},
      {'key': 'text', 'label': 'Plain Text', 'icon': Icons.text_fields_rounded},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.file_present_rounded,
                  size: 16, color: accent.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                'Export Format',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: formats.map((f) {
              final selected = provider.format == f['key'];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: f == formats.last ? 0 : 8,
                  ),
                  child: GestureDetector(
                    onTap: () => provider.setFormat(f['key'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? accent.withOpacity(0.15)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? accent.withOpacity(0.4)
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            f['icon'] as IconData,
                            size: 20,
                            color: selected
                                ? accent
                                : Colors.white.withOpacity(0.4),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            f['label'] as String,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePicker(Color accent, ChatExportProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_rounded,
                  size: 16, color: accent.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                'Theme',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(exportThemes.length, (i) {
                final t = exportThemes[i];
                final selected = provider.themeIndex == i;
                return GestureDetector(
                  onTap: () => provider.setTheme(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < exportThemes.length - 1 ? 10 : 0),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? t.primary
                          : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? t.accent.withOpacity(0.6)
                            : Colors.white.withOpacity(0.05),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                            gradient: LinearGradient(
                              colors: [t.accent, t.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.name,
                          style: TextStyle(
                            color: selected
                                ? t.textPrimary
                                : Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: t.accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(Color accent, ChatExportProvider provider) {
    if (provider.selectedConversation == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.arrow_upward_rounded,
                  size: 24, color: Colors.white.withOpacity(0.15)),
              const SizedBox(height: 8),
              Text(
                'Select a conversation above\nto generate a preview',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!provider.isGenerating && provider.previewContent.isEmpty) {
      // Show generate button
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                'Ready to export "${provider.selectedConversation!.title}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => provider.generatePreview(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_rounded,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Generate Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.isGenerating) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Generating...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isMarkdown = provider.format == 'markdown';
    final isHtml = provider.format == 'html';
    final formatLabel = isMarkdown
        ? '.md'
        : isHtml
            ? '.html'
            : '.txt';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.preview_rounded,
                    size: 14, color: accent.withOpacity(0.6)),
                const SizedBox(width: 6),
                Text(
                  'Preview',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formatLabel,
                    style: TextStyle(
                      color: accent.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.white.withOpacity(0),
                ],
                stops: const [0, 0.9, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: SelectableText(
                  provider.previewContent,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
