import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/memory_node.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

const _uuid = Uuid();

const _categoryColors = {
  'general': Color(0xFF7C4DFF),
  'fact': Color(0xFF448AFF),
  'preference': Color(0xFFE040FB),
  'personal': Color(0xFF00E676),
  'interest': Color(0xFFFF9100),
  'project': Color(0xFFFF4081),
};

const _categoryIcons = {
  'general': Icons.circle_outlined,
  'fact': Icons.verified_outlined,
  'preference': Icons.favorite_outline,
  'personal': Icons.person_outline,
  'interest': Icons.explore_outlined,
  'project': Icons.folder_outlined,
};

class MemoryConstellationScreen extends StatefulWidget {
  const MemoryConstellationScreen({super.key});

  @override
  State<MemoryConstellationScreen> createState() =>
      _MemoryConstellationScreenState();
}

class _MemoryConstellationScreenState
    extends State<MemoryConstellationScreen> with TickerProviderStateMixin {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  late AnimationController _driftController;
  final Map<String, AnimationController> _nodePulseControllers = {};

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _driftController.dispose();
    _searchController.dispose();
    for (final c in _nodePulseControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<MemoryNode> _filtered(List<MemoryNode> all) {
    var result = all;
    if (_selectedCategory != 'all') {
      result = result.where((m) => m.category == _selectedCategory).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((m) =>
        m.content.toLowerCase().contains(q) ||
        m.tags.any((t) => t.toLowerCase().contains(q))
      ).toList();
    }
    return result;
  }

  void _showMemoryDetail(MemoryNode memory) {
    HapticFeedback.mediumImpact();
    final accent = context.read<SettingsProvider>().accentColor;
    final provider = context.read<ChatProvider>();
    final contentController = TextEditingController(text: memory.content);
    final category = memory.category;
    final tagsController = TextEditingController(
      text: memory.tags.join(', '),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _categoryColor(category).withOpacity(0.15),
                  ),
                  child: Icon(
                    _categoryIcon(category),
                    color: _categoryColor(category),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category[0].toUpperCase() + category.substring(1),
                        style: TextStyle(
                          color: _categoryColor(category),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'Created ${_formatDate(memory.createdAt)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                  onPressed: () {
                    Navigator.pop(ctx);
                    provider.deleteMemory(memory.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 4,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Memory content',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagsController,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: 'Tags (comma-separated)',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [accent, const Color(0xFF448AFF)],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      final updated = MemoryNode(
                        id: memory.id,
                        content: contentController.text.trim(),
                        category: memory.category,
                        tags: tagsController.text
                            .split(',')
                            .map((t) => t.trim())
                            .where((t) => t.isNotEmpty)
                            .toList(),
                        createdAt: memory.createdAt,
                        importance: memory.importance,
                      );
                      provider.updateMemory(updated);
                      Navigator.pop(ctx);
                    },
                    child: const Center(
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMemory() {
    final accent = context.read<SettingsProvider>().accentColor;
    final provider = context.read<ChatProvider>();
    final contentController = TextEditingController();
    var selectedCategory = 'general';
    final tagsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20, right: 20, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New Memory',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 4,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'What should Nexus remember about you?',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Category',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: memoryCategories.map((cat) {
                  final active = cat == selectedCategory;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: active
                            ? _categoryColor(cat).withOpacity(0.2)
                            : Colors.white.withOpacity(0.04),
                        border: Border.all(
                          color: active
                              ? _categoryColor(cat).withOpacity(0.4)
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _categoryIcon(cat),
                            size: 14,
                            color: active
                                ? _categoryColor(cat)
                                : Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cat[0].toUpperCase() + cat.substring(1),
                            style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsController,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
                decoration: InputDecoration(
                  hintText: 'Tags (comma-separated)',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: [accent, const Color(0xFF448AFF)],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        final text = contentController.text.trim();
                        if (text.isEmpty) return;
                        provider.addMemory(MemoryNode(
                          id: _uuid.v4(),
                          content: text,
                          category: selectedCategory,
                          tags: tagsController.text
                              .split(',')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList(),
                        ));
                        Navigator.pop(ctx);
                      },
                      child: const Center(
                        child: Text(
                          'Add Memory',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final provider = context.watch<ChatProvider>();
    final allMemories = provider.memories;
    final filtered = _filtered(allMemories);

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
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, const Color(0xFFE040FB)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Memory Core',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.search_rounded,
                color: Colors.white.withOpacity(0.6),
                size: 22,
              ),
              onPressed: () => _showSearch(context, allMemories),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilterChips(accent),
            Expanded(
              child: allMemories.isEmpty
                  ? _buildEmptyState(accent)
                  : filtered.isEmpty
                      ? _buildNoResults(accent)
                      : _buildConstellation(filtered, accent),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMemory,
          backgroundColor: accent,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFilterChips(Color accent) {
    final categories = ['all', ...memoryCategories];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final active = cat == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: active
                        ? (cat == 'all'
                            ? accent.withOpacity(0.2)
                            : _categoryColor(cat).withOpacity(0.2))
                        : Colors.white.withOpacity(0.04),
                    border: Border.all(
                      color: active
                          ? (cat == 'all'
                              ? accent.withOpacity(0.4)
                              : _categoryColor(cat).withOpacity(0.4))
                          : Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cat != 'all')
                        Icon(
                          _categoryIcon(cat),
                          size: 12,
                          color: active
                              ? _categoryColor(cat)
                              : Colors.white.withOpacity(0.3),
                        ),
                      if (cat != 'all') const SizedBox(width: 4),
                      Text(
                        cat == 'all' ? 'All' : cat[0].toUpperCase() + cat.substring(1),
                        style: TextStyle(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.08), accent.withOpacity(0.02)],
              ),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 44,
              color: accent.withOpacity(0.25),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Memory Constellation',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first memory',
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Facts, preferences, interests — Nexus will remember',
            style: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48,
              color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'No memories match',
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

  Widget _buildConstellation(List<MemoryNode> nodes, Color accent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final positions = _computePositions(nodes, constraints);
        return Stack(
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ConnectionPainter(
                positions: positions,
                accent: accent,
              ),
            ),
            ...positions.map((pos) => _buildNodeWidget(
              pos.node,
              pos.x, pos.y,
              pos.index,
              accent,
            )),
          ],
        );
      },
    );
  }

  Widget _buildNodeWidget(
      MemoryNode node, double x, double y, int index, Color accent) {
    final catColor = _categoryColor(node.category);
    final icon = _categoryIcon(node.category);
    final size = 40.0 + node.importance * 30;

    if (!_nodePulseControllers.containsKey(node.id)) {
      _nodePulseControllers[node.id] = AnimationController(
        vsync: this,
        duration: Duration(seconds: 3 + (index % 3)),
      )..repeat(reverse: true);
    }
    final pulse = _nodePulseControllers[node.id]!;

    return AnimatedBuilder(
      animation: _driftController,
      builder: (context, _) {
        final driftX = sin(_driftController.value * 2 * pi + index * 1.7) * 6;
        final driftY = cos(_driftController.value * 2 * pi + index * 2.3) * 6;
        final glow = pulse.value;

        return Positioned(
          left: x + driftX - size / 2,
          top: y + driftY - size / 2,
          child: GestureDetector(
            onTap: () => _showMemoryDetail(node),
            child: AnimatedBuilder(
              animation: pulse,
              builder: (context, _) {
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: catColor.withOpacity(0.15 + glow * 0.15),
                        blurRadius: 8 + glow * 12,
                        spreadRadius: 1 + glow * 3,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: catColor.withOpacity(0.4 + glow * 0.3),
                            width: 1.5,
                          ),
                          gradient: RadialGradient(
                            colors: [
                              catColor.withOpacity(0.15 + glow * 0.1),
                              catColor.withOpacity(0.02),
                            ],
                          ),
                        ),
                      ),
                      Icon(icon, size: size * 0.4,
                          color: catColor.withOpacity(0.6 + glow * 0.3)),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  List<_NodePosition> _computePositions(
      List<MemoryNode> nodes, BoxConstraints constraints) {
    final positions = <_NodePosition>[];
    final random = Random(42);
    final centerX = constraints.maxWidth / 2;
    final centerY = constraints.maxHeight / 2;
    final radius = min(constraints.maxWidth, constraints.maxHeight) * 0.35;

    for (var i = 0; i < nodes.length; i++) {
      final angle = (2 * pi / nodes.length) * i + random.nextDouble() * 0.3;
      final r = radius * (0.5 + random.nextDouble() * 0.5);
      final x = centerX + cos(angle) * r;
      final y = centerY + sin(angle) * r;
      positions.add(_NodePosition(
        node: nodes[i],
        x: x.clamp(30, constraints.maxWidth - 30),
        y: y.clamp(30, constraints.maxHeight - 30),
        index: i,
      ));
    }
    return positions;
  }

  void _showSearch(BuildContext context, List<MemoryNode> all) {
    showSearch(
      context: context,
      delegate: _MemorySearchDelegate(all, (node) {
        Navigator.pop(context);
        _showMemoryDetail(node);
      }),
    );
  }

  Color _categoryColor(String category) =>
      _categoryColors[category] ?? const Color(0xFF7C4DFF);

  IconData _categoryIcon(String category) =>
      _categoryIcons[category] ?? Icons.circle_outlined;

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.month}/${d.day}';
  }
}

class _NodePosition {
  final MemoryNode node;
  final double x;
  final double y;
  final int index;
  _NodePosition({
    required this.node,
    required this.x,
    required this.y,
    required this.index,
  });
}

class _ConnectionPainter extends CustomPainter {
  final List<_NodePosition> positions;
  final Color accent;

  _ConnectionPainter({required this.positions, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < positions.length; i++) {
      for (var j = i + 1; j < positions.length; j++) {
        final a = positions[i];
        final b = positions[j];
        final dist = sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2));
        if (dist > 200) continue;

        final opacity = (1 - dist / 200) * 0.15;
        final paint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

        canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MemorySearchDelegate extends SearchDelegate<String> {
  final List<MemoryNode> memories;
  final Function(MemoryNode) onTap;

  _MemorySearchDelegate(this.memories, this.onTap);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0A0F),
        iconTheme: IconThemeData(color: Colors.white70),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Color(0x55FFFFFF)),
        border: InputBorder.none,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF7C4DFF),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white54),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white54),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.toLowerCase();
    final results = q.isEmpty
        ? memories.take(20).toList()
        : memories.where((m) =>
            m.content.toLowerCase().contains(q) ||
            m.tags.any((t) => t.toLowerCase().contains(q))
          ).toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          q.isEmpty ? 'Type to search memories' : 'No memories found',
          style: TextStyle(color: Colors.white.withOpacity(0.3)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final m = results[i];
        final catColor = _categoryColors[m.category] ?? const Color(0xFF7C4DFF);
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: ListTile(
            leading: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: catColor.withOpacity(0.15),
              ),
              child: Icon(
                _categoryIcons[m.category] ?? Icons.circle_outlined,
                size: 14, color: catColor,
              ),
            ),
            title: Text(
              m.content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              m.category,
              style: TextStyle(
                color: catColor.withOpacity(0.5),
                fontSize: 11,
                fontFamily: 'Inter',
              ),
            ),
            onTap: () {
              close(context, '');
              onTap(m);
            },
          ),
        );
      },
    );
  }
}
