import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/knowledge_graph.dart';
import '../models/chat_message.dart';
import '../providers/knowledge_graph_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class KnowledgeGraphScreen extends StatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen> {
  final _transformCtrl = TransformationController();
  String? _selectedNodeId;
  String _searchQuery = '';
  String? _filterType;
  bool _showLabels = true;

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  void _extractAll() {
    final chatProvider = context.read<ChatProvider>();
    final graphProvider = context.read<KnowledgeGraphProvider>();

    final allMessages = <dynamic>[];
    for (final conv in chatProvider.conversations) {
      allMessages.addAll(conv.messages);
    }

    graphProvider.extractFromMessages(
      allMessages.cast<ChatMessage>(),
    );
  }

  void _showNodeDetails(KnowledgeNode node) {
    final accent = context.read<SettingsProvider>().accentColor;
    final graphProvider = context.read<KnowledgeGraphProvider>();
    final connected = graphProvider.getConnectedNodes(node.id);
    final nodeEdges = graphProvider.getNodeEdges(node.id);

    setState(() => _selectedNodeId = node.id);

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
          bottom: MediaQuery.of(ctx).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(node.colorValue).withOpacity(0.15),
                    ),
                    child: Icon(
                      Icons.trip_origin_rounded,
                      color: Color(node.colorValue),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                        Text(
                          '${node.type} · ${node.frequency} mentions',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      graphProvider.removeNode(node.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Connected to',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ),
            if (connected.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'No direct connections',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 13,
                  ),
                ),
              )
            else
              ...connected.map((c) {
                final edge = nodeEdges.firstWhere(
                  (e) => e.sourceId == c.id || e.targetId == c.id,
                );
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(c.colorValue).withOpacity(0.15),
                    ),
                    child: Center(
                      child: Text(
                        '${edge.weight.toInt()}',
                        style: TextStyle(
                          color: Color(c.colorValue).withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    c.label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(c.colorValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      c.type,
                      style: TextStyle(
                        color: Color(c.colorValue).withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }),
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
              _buildToolbar(accent),
              Expanded(
                child: Consumer<KnowledgeGraphProvider>(
                  builder: (context, provider, _) {
                    if (!provider.initialized) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    if (provider.nodes.isEmpty) {
                      return _buildEmptyState(accent, provider);
                    }

                    return _buildGraph(provider, accent);
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
              Text(
                'Knowledge Graph',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const Spacer(),
              Consumer<KnowledgeGraphProvider>(
                builder: (context, provider, _) {
                  return Text(
                    '${provider.nodes.length} nodes',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 12,
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

  Widget _buildToolbar(Color accent) {
    return Consumer<KnowledgeGraphProvider>(
      builder: (context, provider, _) {
        final typeCounts = <String, int>{};
        for (final node in provider.nodes) {
          typeCounts[node.type] = (typeCounts[node.type] ?? 0) + 1;
        }
        final types = typeCounts.keys.toList()..sort();

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: TextField(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search nodes...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 16,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showLabels = !_showLabels),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _showLabels
                            ? Icons.label_rounded
                            : Icons.label_off_rounded,
                        size: 16,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _transformCtrl.value = Matrix4.identity();
                      setState(() => _selectedNodeId = null);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.center_focus_strong_rounded,
                        size: 16,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: provider.nodes.isNotEmpty
                        ? () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF12121A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text('Clear Graph'),
                                content: const Text(
                                  'Remove all nodes and rebuild from conversations?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      provider.clearAll();
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
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              if (types.isNotEmpty) ...[
                const SizedBox(height: 6),
                SizedBox(
                  height: 28,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filterType == null,
                        accent: accent,
                        onTap: () => setState(() => _filterType = null),
                      ),
                      const SizedBox(width: 4),
                      ...types.map((type) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _FilterChip(
                          label: '$type (${typeCounts[type]})',
                          selected: _filterType == type,
                          accent: accent,
                          onTap: () =>
                              setState(() => _filterType = type),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(Color accent, KnowledgeGraphProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.12), accent.withOpacity(0.03)],
              ),
            ),
            child: Icon(
              Icons.hub_outlined,
              size: 40,
              color: accent.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No knowledge graph yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Extract topics and concepts from your conversations',
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: provider.isExtracting ? null : _extractAll,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: provider.isExtracting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'Extract from Conversations',
                          style: TextStyle(
                            color: Colors.white,
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
    );
  }

  Widget _buildGraph(KnowledgeGraphProvider provider, Color accent) {
    var nodes = provider.nodes.toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      nodes = nodes.where((n) =>
        n.label.toLowerCase().contains(q)
      ).toList();
    }

    if (_filterType != null) {
      nodes = nodes.where((n) => n.type == _filterType).toList();
    }

    final nodeIds = nodes.map((n) => n.id).toSet();
    final visibleEdges = provider.edges.where((e) =>
      nodeIds.contains(e.sourceId) && nodeIds.contains(e.targetId)
    ).toList();

    if (nodes.isEmpty) {
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
              'No matching nodes',
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

    return InteractiveViewer(
      transformationController: _transformCtrl,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.2,
      maxScale: 4,
      child: GestureDetector(
        onTap: () => setState(() => _selectedNodeId = null),
        child: SizedBox(
          width: 800,
          height: 800,
          child: Stack(
            children: [
              CustomPaint(
                painter: _EdgePainter(
                  edges: visibleEdges,
                  nodes: nodes,
                  accent: accent,
                ),
                size: const Size(800, 800),
              ),
              ...nodes.map((node) {
                final isSelected = node.id == _selectedNodeId;
                final connectedIds = visibleEdges
                    .where((e) =>
                        e.sourceId == node.id || e.targetId == node.id)
                    .expand((e) => [e.sourceId, e.targetId])
                    .toSet();

                final isConnected = isSelected
                    ? true
                    : _selectedNodeId != null && connectedIds.contains(node.id);

                return Positioned(
                  left: node.x - _nodeSize(node) / 2,
                  top: node.y - _nodeSize(node) / 2,
                  child: GestureDetector(
                    onTap: () => _showNodeDetails(node),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: _nodeSize(node),
                          height: _nodeSize(node),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected || _selectedNodeId == null
                                ? Color(node.colorValue).withOpacity(
                                    isSelected ? 0.3 : 0.15)
                                : Colors.white.withOpacity(0.03),
                            border: Border.all(
                              color: isSelected
                                  ? Color(node.colorValue)
                                  : Color(node.colorValue).withOpacity(
                                      isConnected ? 0.6 : 0.3),
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Color(node.colorValue)
                                          .withOpacity(0.4),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              node.label.isNotEmpty
                                  ? node.label[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: isConnected || _selectedNodeId == null
                                    ? Color(node.colorValue)
                                    : Colors.white.withOpacity(0.15),
                                fontSize: _nodeSize(node) * 0.4,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                          ),
                        ),
                        if (_showLabels)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              node.label.length > 20
                                  ? '${node.label.substring(0, 17)}...'
                                  : node.label,
                              style: TextStyle(
                                color: isConnected ||
                                        _selectedNodeId == null
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.white.withOpacity(0.1),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  double _nodeSize(KnowledgeNode node) {
    return 24 + node.importance * 28;
  }
}

class _EdgePainter extends CustomPainter {
  final List<KnowledgeEdge> edges;
  final List<KnowledgeNode> nodes;
  final Color accent;

  _EdgePainter({
    required this.edges,
    required this.nodes,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = <String, KnowledgeNode>{};
    for (final node in nodes) {
      nodeMap[node.id] = node;
    }

    for (final edge in edges) {
      final source = nodeMap[edge.sourceId];
      final target = nodeMap[edge.targetId];
      if (source == null || target == null) continue;

      final paint = Paint()
        ..color = accent.withOpacity((edge.weight / (edge.weight + 5)))
        ..strokeWidth = 0.5 + edge.weight * 0.3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(source.x, source.y),
        Offset(target.x, target.y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) => true;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? accent.withOpacity(0.2)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accent.withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : Colors.white.withOpacity(0.5),
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
