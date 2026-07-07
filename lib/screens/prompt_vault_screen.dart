import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/prompt_vault_provider.dart';
import '../providers/settings_provider.dart';
import '../models/saved_prompt.dart';
import '../widgets/gradient_mesh_background.dart';

class PromptVaultScreen extends StatefulWidget {
  final bool pickerMode;
  final ValueChanged<String>? onPromptPicked;

  const PromptVaultScreen({
    super.key,
    this.pickerMode = false,
    this.onPromptPicked,
  });

  @override
  State<PromptVaultScreen> createState() => _PromptVaultScreenState();
}

class _PromptVaultScreenState extends State<PromptVaultScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSavePromptDialog({SavedPrompt? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(text: existing?.content ?? '');
    final tagsController = TextEditingController(
      text: existing?.tags.join(', ') ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          existing != null ? 'Edit Prompt' : 'Save Prompt',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Prompt title...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Prompt content...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tags (comma separated)...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ],
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
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              if (title.isEmpty || content.isEmpty) return;

              final tags = tagsController.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();

              final provider = context.read<PromptVaultProvider>();
              if (existing != null) {
                provider.updatePrompt(existing.copyWith(
                  title: title,
                  content: content,
                  tags: tags,
                ));
              } else {
                provider.addPrompt(title: title, content: content, tags: tags);
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF7C4DFF)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPromptActions(SavedPrompt prompt) {
    final accent = context.read<SettingsProvider>().accentColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).padding.bottom + 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _menuOption(
              icon: Icons.edit_rounded,
              label: 'Edit',
              accent: accent,
              onTap: () {
                Navigator.pop(ctx);
                _showSavePromptDialog(existing: prompt);
              },
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.04)),
            _menuOption(
              icon: Icons.content_copy_rounded,
              label: 'Copy to Clipboard',
              accent: accent,
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: prompt.content));
                HapticFeedback.lightImpact();
              },
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.04)),
            _menuOption(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              accent: Colors.red.shade400,
              onTap: () {
                Navigator.pop(ctx);
                context.read<PromptVaultProvider>().deletePrompt(prompt.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _menuOption({
    required IconData icon,
    required String label,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 15,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      body: GradientMeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(accent),
              _buildTagBar(accent),
              Expanded(
                child: Consumer<PromptVaultProvider>(
                  builder: (context, provider, _) {
                    final prompts = provider.filteredPrompts;

                    if (provider.prompts.isEmpty) {
                      return _buildEmptyState(accent);
                    }

                    if (prompts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No matching prompts',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 16,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                      itemCount: prompts.length,
                      itemBuilder: (context, index) {
                        final prompt = prompts[index];
                        return _PromptCard(
                          prompt: prompt,
                          accent: accent,
                          pickerMode: widget.pickerMode,
                          onTap: () {
                            if (widget.pickerMode) {
                              widget.onPromptPicked?.call(prompt.content);
                              provider.incrementUsage(prompt.id);
                              Navigator.pop(context);
                            } else {
                              _showPromptActions(prompt);
                            }
                          },
                          onLongPress: () => _showPromptActions(prompt),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSavePromptDialog(),
        backgroundColor: accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Prompt',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'SpaceGrotesk',
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
                  widget.pickerMode
                      ? Icons.close_rounded
                      : Icons.arrow_back_rounded,
                  color: Colors.white.withOpacity(0.6),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              if (!_searchController.text.isNotEmpty)
                Text(
                  widget.pickerMode ? 'Select Prompt' : 'Prompt Vault',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              if (_searchController.text.isNotEmpty) ...[
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    context.read<PromptVaultProvider>().setSearchQuery('');
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagBar(Color accent) {
    return Consumer<PromptVaultProvider>(
      builder: (context, provider, _) {
        final tags = provider.allTags;
        if (tags.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _TagChip(
                      label: 'All',
                      selected: provider.activeTag == null,
                      accent: accent,
                      onTap: () => provider.setActiveTag(null),
                    ),
                    const SizedBox(width: 6),
                    ...tags.map((tag) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _TagChip(
                        label: tag,
                        selected: provider.activeTag == tag,
                        accent: accent,
                        onTap: () => provider.setActiveTag(tag),
                        onRemove: () => _removeTagFromAll(tag, provider),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 36,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search prompts...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: provider.setSearchQuery,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeTagFromAll(String tag, PromptVaultProvider provider) {
    for (final prompt in provider.prompts) {
      if (prompt.tags.contains(tag)) {
        provider.removeTagFromPrompt(prompt.id, tag);
      }
    }
  }

  Widget _buildEmptyState(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.12), accent.withOpacity(0.03)],
              ),
            ),
            child: Icon(
              Icons.bookmark_outline_rounded,
              size: 36,
              color: accent.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No saved prompts yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Long-press a message to save it as a prompt',
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withOpacity(0.2)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent.withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? accent : Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Inter',
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: selected
                      ? accent.withOpacity(0.6)
                      : Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final SavedPrompt prompt;
  final Color accent;
  final bool pickerMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PromptCard({
    required this.prompt,
    required this.accent,
    required this.pickerMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final preview = prompt.content.length > 120
        ? '${prompt.content.substring(0, 117)}...'
        : prompt.content;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: pickerMode
                ? accent.withOpacity(0.2)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.12),
                  ),
                  child: Icon(
                    Icons.bookmark_rounded,
                    size: 14,
                    color: accent.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    prompt.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (prompt.usageCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${prompt.usageCount}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                if (pickerMode)
                  Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: accent.withOpacity(0.6),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
                fontFamily: 'Inter',
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (prompt.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: prompt.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: accent.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
