import 'package:flutter/material.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/conversation_branch.dart';
import '../providers/chat_provider.dart';

class TimeMachineScreen extends StatefulWidget {
  final ChatConversation conversation;
  final ChatProvider provider;

  const TimeMachineScreen({
    super.key,
    required this.conversation,
    required this.provider,
  });

  @override
  State<TimeMachineScreen> createState() => _TimeMachineScreenState();
}

class _TreeNode {
  final String messageId;
  final String content;
  final String role;
  final List<_TreeNode> children;
  _TreeNode? parent;
  final String branchId;

  _TreeNode({
    required this.messageId,
    required this.content,
    required this.role,
    required this.branchId,
    List<_TreeNode>? children,
  }) : children = children ?? [];

  bool get isUser => role == 'user';
  String get preview => content.length > 50
      ? '${content.substring(0, 47)}...'
      : content;
}

class _BranchLayout {
  final ConversationBranch branch;
  final Color color;
  final List<_TreeNode> nodes;

  _BranchLayout({
    required this.branch,
    required this.color,
    required this.nodes,
  });
}

class _TimeMachineScreenState extends State<TimeMachineScreen> {
  static const List<Color> _palette = [
    Color(0xFF7C4DFF),
    Color(0xFF448AFF),
    Color(0xFFFF4081),
    Color(0xFF00E676),
    Color(0xFFFFAB00),
    Color(0xFFE040FB),
    Color(0xFF00BCD4),
    Color(0xFFFF6D00),
  ];

  late List<_BranchLayout> _branches;
  final Map<String, _TreeNode> _nodeMap = {};
  int? _selectedIdx;
  bool _showLabels = true;

  @override
  void initState() {
    super.initState();
    _buildTree();
  }

  void _buildTree() {
    _nodeMap.clear();
    final conv = widget.conversation;
    final branches = <_BranchLayout>[];

    for (var i = 0; i < conv.branches.length; i++) {
      final b = conv.branches[i];
      final msgs = conv.branchMessages[b.id] ?? [];
      final color = _palette[i % _palette.length];
      final nodes = <_TreeNode>[];

      for (final m in msgs) {
        final existing = _nodeMap[m.id];
        if (existing != null) {
          nodes.add(existing);
        } else {
          final node = _TreeNode(
            messageId: m.id,
            content: m.content,
            role: m.role,
            branchId: b.id,
          );
          _nodeMap[m.id] = node;
          nodes.add(node);
          if (nodes.length > 1) {
            final prev = nodes[nodes.length - 2];
            prev.children.add(node);
            node.parent = prev;
          }
        }
      }
      branches.add(_BranchLayout(branch: b, color: color, nodes: nodes));
    }

    _branches = branches;
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF7C4DFF);
    final conv = widget.conversation;

    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: Colors.white.withOpacity(0.6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chat Time Machine',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showLabels ? Icons.label_outline : Icons.label_off_outlined,
              color: Colors.white.withOpacity(0.6),
            ),
            onPressed: () => setState(() => _showLabels = !_showLabels),
            tooltip: 'Toggle labels',
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline,
                color: Colors.white.withOpacity(0.6)),
            onPressed: _showCreateBranchSheet,
            tooltip: 'Create branch',
          ),
        ],
      ),
      body: _branches.isEmpty
          ? Center(
              child: Text(
                'No branches yet',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildTreeCanvas(accent),
                ),
              ),
            ),
    );
  }

  Widget _buildTreeCanvas(Color accent) {
    final nodeW = 180.0;
    final nodeH = 60.0;
    final hGap = 40.0;
    final vGap = 24.0;

    final rowMap = <int, List<_TreeRowEntry>>{};
    for (final bl in _branches) {
      for (var i = 0; i < bl.nodes.length; i++) {
        final node = bl.nodes[i];
        rowMap.putIfAbsent(i, () => []);
        if (!rowMap[i]!.any((e) => e.node.messageId == node.messageId)) {
          rowMap[i]!.add(_TreeRowEntry(node: node, branchColor: bl.color));
        }
      }
    }

    final rows = rowMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxCols = rows.fold(0, (max, r) => r.value.length > max ? r.value.length : max);

    final canvasW = maxCols * (nodeW + hGap) + 60;
    final canvasH = rows.length * (nodeH + vGap) + 40;

    return SizedBox(
      width: canvasW,
      height: canvasH,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(canvasW, canvasH),
            painter: _TreePainter(
              rows: rows,
              nodeW: nodeW,
              nodeH: nodeH,
              hGap: hGap,
              vGap: vGap,
              accent: accent,
            ),
          ),
          ..._buildNodeWidgets(rows, nodeW, nodeH, hGap, vGap, accent),
        ],
      ),
    );
  }

  List<Widget> _buildNodeWidgets(
    List<MapEntry<int, List<_TreeRowEntry>>> rows,
    double nodeW,
    double nodeH,
    double hGap,
    double vGap,
    Color accent,
  ) {
    final widgets = <Widget>[];
    final conv = widget.conversation;

    for (final entry in rows) {
      final rowIdx = entry.key;
      final entries = entry.value;
      for (var colIdx = 0; colIdx < entries.length; colIdx++) {
        final e = entries[colIdx];
        final x = 20.0 + colIdx * (nodeW + hGap);
        final y = 20.0 + rowIdx * (nodeH + vGap);
        final isActive = e.node.branchId == conv.activeBranchId;
        final isSelected = _selectedIdx != null &&
            entries.length > _selectedIdx! &&
            colIdx == _selectedIdx;

        widgets.add(
          Positioned(
            left: x,
            top: y,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedIdx = colIdx);
                _showNodeDetail(e.node, e.branchColor);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: nodeW,
                height: nodeH,
                decoration: BoxDecoration(
                  color: e.node.isUser
                      ? e.branchColor.withOpacity(0.08)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? accent
                        : isSelected
                            ? e.branchColor.withOpacity(0.6)
                            : e.branchColor.withOpacity(0.2),
                    width: isActive ? 1.5 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: accent.withOpacity(0.15),
                            blurRadius: 12,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            e.node.isUser
                                ? Icons.person_outline
                                : Icons.auto_awesome,
                            size: 10,
                            color: e.branchColor.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              e.node.isUser ? 'You' : 'AI',
                              style: TextStyle(
                                color: e.branchColor.withOpacity(0.6),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                          ),
                          if (isActive)
                            Icon(Icons.check_circle,
                                size: 10, color: accent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_showLabels)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          e.node.preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 9,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  void _showNodeDetail(_TreeNode node, Color color) {
    final conv = widget.conversation;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: color.withOpacity(0.2)),
          ),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  node.isUser ? 'User Message' : 'AI Response',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _branchChip(node.branchId, accent: color),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Text(
                    node.content,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.provider.switchBranch(node.branchId);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.call_split_rounded, size: 16),
                label: Text(
                  conv.activeBranchId == node.branchId
                      ? 'Already on this branch'
                      : 'Switch to ${_getBranchName(node.branchId)}',
                  style: const TextStyle(fontFamily: 'SpaceGrotesk'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateBranchSheet() {
    final nameCtrl = TextEditingController();
    final accent = const Color(0xFF7C4DFF);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: accent.withOpacity(0.2)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Branch',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A new branch will start from the last message and let you explore a different direction.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TextField(
                controller: nameCtrl,
                autofocus: true,
                style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
                decoration: InputDecoration(
                  hintText: 'Branch name',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontFamily: 'Inter',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final conv = widget.conversation;
                  if (conv.messages.isEmpty) return;

                  final branchId = DateTime.now()
                      .millisecondsSinceEpoch
                      .toString();
                  final branchMsgs = List<ChatMessage>.from(conv.messages);
                  conv.branchMessages[branchId] = branchMsgs;
                  conv.branches.add(ConversationBranch(
                    id: branchId,
                    name: name,
                  ));
                  conv.activeBranchId = branchId;
                  setState(_buildTree);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Create Branch',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBranchName(String branchId) {
    final branch =
        widget.conversation.branches.where((b) => b.id == branchId).firstOrNull;
    return branch?.name ?? 'Unknown';
  }

  Widget _branchChip(String branchId, {required Color accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Text(
        _getBranchName(branchId),
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TreeRowEntry {
  final _TreeNode node;
  final Color branchColor;

  _TreeRowEntry({required this.node, required this.branchColor});
}

class _TreePainter extends CustomPainter {
  final List<MapEntry<int, List<_TreeRowEntry>>> rows;
  final double nodeW;
  final double nodeH;
  final double hGap;
  final double vGap;
  final Color accent;

  _TreePainter({
    required this.rows,
    required this.nodeW,
    required this.nodeH,
    required this.hGap,
    required this.vGap,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final entry in rows) {
      final rowIdx = entry.key;
      final entries = entry.value;

      for (var ci = 0; ci < entries.length; ci++) {
        final e = entries[ci];
        final cx = 20.0 + ci * (nodeW + hGap) + nodeW / 2;
        final cy = 20.0 + rowIdx * (nodeH + vGap) + nodeH / 2;

        paint.color = e.branchColor.withOpacity(0.3);
        canvas.drawCircle(Offset(cx, cy), 3, paint);

        if (e.node.parent != null) {
          final parentRowIdx = rowIdx - 1;
          if (parentRowIdx >= 0) {
            final parentEntry = rows
                .where((r) => r.key == parentRowIdx)
                .expand((r) => r.value)
                .where((pe) => pe.node.messageId == e.node.parent!.messageId)
                .firstOrNull;

            if (parentEntry != null) {
              final pIdx = rows
                  .firstWhere((r) => r.key == parentRowIdx)
                  .value
                  .indexOf(parentEntry);
              final pCx = 20.0 + pIdx * (nodeW + hGap) + nodeW / 2;
              final pCy = 20.0 + parentRowIdx * (nodeH + vGap) + nodeH / 2;

              paint.color = e.branchColor.withOpacity(0.4);
              paint.strokeWidth = 1.5;

              if (pIdx == ci) {
                canvas.drawLine(Offset(pCx, pCy), Offset(cx, cy), paint);
              } else {
                final midY = (pCy + cy) / 2;
                final path = Path()
                  ..moveTo(pCx, pCy)
                  ..lineTo(pCx, midY)
                  ..lineTo(cx, midY)
                  ..lineTo(cx, cy);
                canvas.drawPath(path, paint);
              }
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TreePainter oldDelegate) => true;
}
