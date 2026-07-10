import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/code_snippet.dart';
import '../providers/snippet_vault_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';
import '../widgets/syntax_highlighter.dart';

class SnippetVaultScreen extends StatefulWidget {
  const SnippetVaultScreen({super.key});

  @override
  State<SnippetVaultScreen> createState() => _SnippetVaultScreenState();
}

class _SnippetVaultScreenState extends State<SnippetVaultScreen> {
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();
  String _selectedLanguage = 'dart';
  bool _isEditing = false;
  CodeSnippet? _editingSnippet;

  static const _languages = [
    'dart', 'python', 'javascript', 'typescript', 'java', 'kotlin',
    'swift', 'go', 'rust', 'cpp', 'c', 'ruby', 'php', 'sql',
    'html', 'css', 'yaml', 'json', 'bash', 'markdown',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _codeController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Snippet Vault',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddDialog(context, accent),
          ),
        ],
      ),
      body: GradientMeshBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildSearchBar(accent),
            _buildFilterChips(accent),
            Expanded(
              child: Consumer<SnippetVaultProvider>(
                builder: (context, provider, _) {
                  final snippets = provider.filteredSnippets;
                  if (snippets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.code, size: 64, color: accent.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            provider.searchQuery.isEmpty
                                ? 'No snippets saved yet'
                                : 'No matching snippets',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _showAddDialog(context, accent),
                            icon: Icon(Icons.add, size: 18, color: accent),
                            label: Text('Add Snippet', style: TextStyle(color: accent)),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: snippets.length,
                    itemBuilder: (context, index) {
                      return _buildSnippetCard(snippets[index], accent);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          onChanged: (v) => context.read<SnippetVaultProvider>().setSearchQuery(v),
          decoration: InputDecoration(
            hintText: 'Search snippets...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.3), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18, color: Colors.white.withOpacity(0.4)),
                    onPressed: () {
                      _searchController.clear();
                      context.read<SnippetVaultProvider>().setSearchQuery('');
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(Color accent) {
    return Consumer<SnippetVaultProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 48,
          margin: const EdgeInsets.only(top: 10),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _filterChip('All', provider.activeLanguage == null && provider.activeTag == null, accent, () {
                provider.setActiveLanguage(null);
                provider.setActiveTag(null);
              }),
              ...provider.allLanguages.map((lang) {
                return _filterChip(lang, provider.activeLanguage == lang, accent, () {
                  provider.setActiveTag(null);
                  provider.setActiveLanguage(provider.activeLanguage == lang ? null : lang);
                });
              }),
              ...provider.allTags.map((tag) {
                return _filterChip('#$tag', provider.activeTag == tag, accent, () {
                  provider.setActiveLanguage(null);
                  provider.setActiveTag(provider.activeTag == tag ? null : tag);
                });
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, bool selected, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent.withOpacity(0.4) : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: selected ? accent : Colors.white60,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildSnippetCard(CodeSnippet snippet, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    snippet.language,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    snippet.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: Colors.white.withOpacity(0.4)),
                  onSelected: (value) {
                    if (value == 'edit') _showEditDialog(context, accent, snippet);
                    if (value == 'delete') _confirmDelete(context, snippet);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  color: const Color(0xFF1A1A2E),
                ),
              ],
            ),
          ),
          if (snippet.description != null && snippet.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                snippet.description!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              snippet.code.length > 500
                  ? '${snippet.code.substring(0, 500)}...'
                  : snippet.code,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: const Color(0xFFE0E0E0),
                height: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                if (snippet.tags.isNotEmpty) ...[
                  ...snippet.tags.take(3).map((tag) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '#$tag',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ),
                      )),
                  const Spacer(),
                ] else
                  const Spacer(),
                _actionButton(
                  Icons.copy_rounded,
                  'Copy',
                  accent,
                  () {
                    Clipboard.setData(ClipboardData(text: snippet.code));
                    context.read<SnippetVaultProvider>().incrementCopyCount(snippet.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied!', style: GoogleFonts.inter(fontSize: 13)),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _actionButton(
                  Icons.fullscreen,
                  'Expand',
                  accent,
                  () => _showFullCode(context, snippet, accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accent.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: accent.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, Color accent) {
    _isEditing = false;
    _editingSnippet = null;
    _titleController.clear();
    _codeController.clear();
    _descController.clear();
    _tagsController.clear();
    _selectedLanguage = 'dart';
    _showSnippetDialog(context, accent, title: 'Save Snippet');
  }

  void _showEditDialog(BuildContext context, Color accent, CodeSnippet snippet) {
    _isEditing = true;
    _editingSnippet = snippet;
    _titleController.text = snippet.title;
    _codeController.text = snippet.code;
    _descController.text = snippet.description ?? '';
    _tagsController.text = snippet.tags.join(', ');
    _selectedLanguage = snippet.language;
    _showSnippetDialog(context, accent, title: 'Edit Snippet');
  }

  void _showSnippetDialog(BuildContext context, Color accent, {required String title}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _saveSnippet(context);
                        Navigator.pop(ctx);
                      },
                      child: Text('Save', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildField('Title', _titleController, hint: 'e.g. HTTP GET Request'),
                    const SizedBox(height: 12),
                    _buildField('Description', _descController, hint: 'Optional description', maxLines: 2),
                    const SizedBox(height: 12),
                    _buildField('Tags', _tagsController, hint: 'comma separated: flutter, api, http'),
                    const SizedBox(height: 12),
                    _buildLanguageDropdown(setModalState),
                    const SizedBox(height: 12),
                    _buildField('Code', _codeController, hint: 'Paste your code here...', maxLines: 12, isCode: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            value: _selectedLanguage,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF1A1A2E),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            items: _languages.map((l) {
              return DropdownMenuItem(value: l, child: Text(l));
            }).toList(),
            onChanged: (v) => setModalState(() => _selectedLanguage = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {String? hint, int maxLines = 1, bool isCode = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isCode ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: isCode
                ? GoogleFonts.jetBrainsMono(fontSize: 13, color: const Color(0xFFE0E0E0), height: 1.5)
                : GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: isCode ? 13 : 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  void _saveSnippet(BuildContext context) {
    final provider = context.read<SnippetVaultProvider>();
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (_isEditing && _editingSnippet != null) {
      provider.updateSnippet(_editingSnippet!.copyWith(
        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Untitled',
        code: _codeController.text,
        language: _selectedLanguage,
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        tags: tags,
      ));
    } else {
      provider.addSnippet(
        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Untitled',
        code: _codeController.text,
        language: _selectedLanguage,
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        tags: tags,
      );
    }
  }

  void _confirmDelete(BuildContext context, CodeSnippet snippet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Snippet?'),
        content: Text(
          'This will permanently delete "${snippet.title}".',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              context.read<SnippetVaultProvider>().deleteSnippet(snippet.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFullCode(BuildContext context, CodeSnippet snippet, Color accent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(snippet.language, style: GoogleFonts.inter(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      snippet.title,
                      style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: accent, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: snippet.code));
                      context.read<SnippetVaultProvider>().incrementCopyCount(snippet.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied!', style: GoogleFonts.inter(fontSize: 13)),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  snippet.code,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: const Color(0xFFE0E0E0),
                    height: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
