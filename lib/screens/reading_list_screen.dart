import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/reading_item.dart';
import '../providers/reading_list_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class ReadingListScreen extends StatefulWidget {
  const ReadingListScreen({super.key});

  @override
  State<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends State<ReadingListScreen> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _urlController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedType = 'book';

  static const _types = ['book', 'article', 'video', 'podcast'];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Reading List',
          style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddDialog(context, accent),
          ),
        ],
      ),
      body: GradientMeshBackground(
        child: Consumer<ReadingListProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                const SizedBox(height: 100),
                _buildStatsRow(provider, accent),
                const SizedBox(height: 12),
                _buildSearchBar(accent, provider),
                const SizedBox(height: 8),
                _buildFilterChips(provider, accent),
                Expanded(
                  child: provider.filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.menu_book, size: 64, color: accent.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                provider.searchQuery.isEmpty
                                    ? 'Your reading list is empty'
                                    : 'No matching items',
                                style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: provider.filteredItems.length,
                          itemBuilder: (context, index) {
                            return _buildItemCard(provider.filteredItems[index], accent);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow(ReadingListProvider provider, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _stat('${provider.toReadCount}', 'To Read', const Color(0xFFFFD740)),
          const SizedBox(width: 8),
          _stat('${provider.readingCount}', 'Reading', accent),
          const SizedBox(width: 8),
          _stat('${provider.completedCount}', 'Done', const Color(0xFF00E676)),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color accent, ReadingListProvider provider) {
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
          onChanged: (v) => provider.setSearchQuery(v),
          decoration: InputDecoration(
            hintText: 'Search reading list...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.3), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ReadingListProvider provider, Color accent) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: ['all', 'to_read', 'reading', 'completed'].map((f) {
          final selected = provider.statusFilter == f;
          final label = f == 'all' ? 'All' : f == 'to_read' ? 'To Read' : f[0].toUpperCase() + f.substring(1);
          return GestureDetector(
            onTap: () => provider.setStatusFilter(f),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? accent.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
              ),
              child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: selected ? accent : Colors.white60, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemCard(ReadingItem item, Color accent) {
    final typeIcons = {'book': Icons.menu_book, 'article': Icons.article, 'video': Icons.play_circle, 'podcast': Icons.headphones};
    final statusColors = {
      'to_read': const Color(0xFFFFD740),
      'reading': accent,
      'completed': const Color(0xFF00E676),
    };
    final color = statusColors[item.status] ?? accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeIcons[item.type] ?? Icons.book, size: 20, color: color.withOpacity(0.7)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    if (item.author != null)
                      Text(item.author!, style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: Colors.white.withOpacity(0.3)),
                onSelected: (v) {
                  if (v == 'edit') _showEditDialog(context, accent, item);
                  if (v == 'delete') _confirmDelete(context, item);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                color: const Color(0xFF1A1A2E),
              ),
            ],
          ),
          if (item.status == 'reading') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.progress / 100,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${item.progress}%', style: GoogleFonts.inter(fontSize: 12, color: color)),
              ],
            ),
          ],
          if (item.rating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<ReadingListProvider>().setRating(item.id, i + 1);
                  },
                  child: Icon(
                    i < item.rating! ? Icons.star : Icons.star_border,
                    size: 18,
                    color: i < item.rating! ? const Color(0xFFFFD740) : Colors.white24,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, Color accent) {
    _titleController.clear();
    _authorController.clear();
    _urlController.clear();
    _selectedType = 'book';
    _showItemDialog(context, accent, title: 'Add to Reading List');
  }

  void _showEditDialog(BuildContext context, Color accent, ReadingItem item) {
    _titleController.text = item.title;
    _authorController.text = item.author ?? '';
    _urlController.text = item.url ?? '';
    _selectedType = item.type;
    _showItemDialog(context, accent, title: 'Edit Item');
  }

  void _showItemDialog(BuildContext context, Color accent, {required String title}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _saveItem(context);
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
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(hintText: 'Title...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)), border: InputBorder.none),
                    ),
                    TextField(
                      controller: _authorController,
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
                      decoration: InputDecoration(hintText: 'Author (optional)', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)), border: InputBorder.none),
                    ),
                    TextField(
                      controller: _urlController,
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
                      decoration: InputDecoration(hintText: 'URL (optional)', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)), border: InputBorder.none),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _types.map((t) {
                        final selected = _selectedType == t;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _selectedType = t),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(t[0].toUpperCase() + t.substring(1),
                                    style: GoogleFonts.inter(fontSize: 12, color: selected ? accent : Colors.white60)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveItem(BuildContext context) {
    if (_titleController.text.trim().isEmpty) return;
    context.read<ReadingListProvider>().addItem(
      title: _titleController.text.trim(),
      author: _authorController.text.trim().isNotEmpty ? _authorController.text.trim() : null,
      url: _urlController.text.trim().isNotEmpty ? _urlController.text.trim() : null,
      type: _selectedType,
    );
  }

  void _confirmDelete(BuildContext context, ReadingItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Item?'),
        content: Text('Remove "${item.title}" from your reading list?', style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
          TextButton(
            onPressed: () {
              context.read<ReadingListProvider>().deleteItem(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
