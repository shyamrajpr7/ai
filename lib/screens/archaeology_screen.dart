import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_conversation.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

const _cellSize = 13.0;
const _cellGap = 3.0;
const _dayLabelWidth = 28.0;
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class ArchaeologyScreen extends StatefulWidget {
  const ArchaeologyScreen({super.key});

  @override
  State<ArchaeologyScreen> createState() => _ArchaeologyScreenState();
}

class _ArchaeologyScreenState extends State<ArchaeologyScreen> {
  DateTime? _selectedDate;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final provider = context.watch<ChatProvider>();
    final counts = provider.getMessageCountsByDay();

    if (counts.isEmpty) {
      return _buildEmpty(accent);
    }

    final sortedDays = counts.keys.toList()..sort();
    final first = sortedDays.first;
    final last = sortedDays.last;
    final endDate = DateTime(last.year, last.month, last.day);
    final startDate = _getStartDate(first);

    final totalDays = endDate.difference(startDate).inDays + 1;
    final weeks = (totalDays / 7).ceil();
    final weekCols = List.generate(weeks, (i) => i);

    final dayRows = <int>[0, 2, 4]; // Mon, Wed, Fri labels

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
              child: Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white.withOpacity(0.7)),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                ),
                child: const Center(child: Icon(Icons.explore_outlined, size: 16, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Archaeology',
                style: TextStyle(color: Colors.white, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${_months[endDate.month - 1]} ${endDate.year}',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${counts.length} days active',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.5)),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.25)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMonthLabels(startDate, weeks),
                      GestureDetector(
                        onTapDown: (details) {
                          final col = (details.localPosition.dx - _dayLabelWidth) / (_cellSize + _cellGap);
                          final row = details.localPosition.dy / (_cellSize + _cellGap);
                          final weekIdx = col.floor();
                          final dayIdx = row.floor();
                          if (weekIdx >= 0 && weekIdx < weeks && dayIdx >= 0 && dayIdx < 7) {
                            final dayNum = weekIdx * 7 + dayIdx;
                            final date = startDate.add(Duration(days: dayNum));
                            if (date.isBefore(endDate.add(const Duration(days: 1))) && !date.isAfter(DateTime.now())) {
                              setState(() => _selectedDate = date);
                            }
                          }
                        },
                        child: SizedBox(
                          width: _dayLabelWidth + weeks * (_cellSize + _cellGap),
                          height: 7 * (_cellSize + _cellGap),
                          child: CustomPaint(
                            painter: _HeatmapPainter(
                              counts: counts,
                              startDate: startDate,
                              endDate: endDate,
                              accent: accent,
                              selectedDate: _selectedDate,
                              weeks: weeks,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildDayDetail(accent, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthLabels(DateTime startDate, int weeks) {
    final labels = <Widget>[];
    var lastMonth = -1;
    for (var w = 0; w < weeks; w++) {
      final date = startDate.add(Duration(days: w * 7 + 3));
      if (date.month != lastMonth) {
        lastMonth = date.month;
        final x = _dayLabelWidth + w * (_cellSize + _cellGap);
        labels.add(Positioned(
          left: x,
          top: 0,
          child: Text(
            _months[date.month - 1],
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontFamily: 'Inter'),
          ),
        ));
      }
    }
    return SizedBox(
      height: 14,
      width: _dayLabelWidth + weeks * (_cellSize + _cellGap),
      child: Stack(children: labels),
    );
  }

  Widget _buildDayDetail(Color accent, ChatProvider provider) {
    if (_selectedDate == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.touch_app_rounded, size: 24, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 6),
            Text('Tap a day on the map above', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13, fontFamily: 'Inter')),
          ],
        ),
      );
    }

    final convs = provider.getConversationsForDate(_selectedDate!);
    final dateStr = '${_months[_selectedDate!.month - 1]} ${_selectedDate!.day}, ${_selectedDate!.year}';
    final count = provider.getMessageCountsByDay()[_selectedDate] ?? 0;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: accent.withOpacity(0.15),
                  ),
                  child: Text(
                    '$count msg${count == 1 ? '' : 's'}',
                    style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: convs.isEmpty
                ? Center(
                    child: Text(
                      'No conversations this day',
                      style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: convs.length,
                    itemBuilder: (context, index) {
                      final conv = convs[index];
                      final preview = conv.messages.isNotEmpty
                          ? conv.messages.last.content
                          : 'Empty';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 14, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    conv.title,
                                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    preview.length > 50 ? '${preview.substring(0, 47)}...' : preview,
                                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                provider.selectConversation(conv.id);
                                Navigator.pop(context);
                              },
                              child: Icon(Icons.chevron_right, size: 18, color: Colors.white.withOpacity(0.2)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color accent) {
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
              child: Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white.withOpacity(0.7)),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                ),
                child: const Center(child: Icon(Icons.explore_outlined, size: 16, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              const Text('Archaeology', style: TextStyle(color: Colors.white, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [accent.withOpacity(0.12), accent.withOpacity(0.03)]),
                ),
                child: Icon(Icons.explore_outlined, size: 40, color: accent.withOpacity(0.3)),
              ),
              const SizedBox(height: 20),
              Text('No conversation history yet', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('Start chatting to see your activity map', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _getStartDate(DateTime first) {
    final start = DateTime(first.year, first.month, first.day).subtract(const Duration(days: 90));
    return start.subtract(Duration(days: start.weekday % 7));
  }
}

class _HeatmapPainter extends CustomPainter {
  final Map<DateTime, int> counts;
  final DateTime startDate;
  final DateTime endDate;
  final Color accent;
  final DateTime? selectedDate;
  final int weeks;

  _HeatmapPainter({
    required this.counts,
    required this.startDate,
    required this.endDate,
    required this.accent,
    required this.selectedDate,
    required this.weeks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var w = 0; w < weeks; w++) {
      for (var d = 0; d < 7; d++) {
        final dayNum = w * 7 + d;
        final date = startDate.add(Duration(days: dayNum));
        if (date.isAfter(endDate) || date.isAfter(DateTime.now())) break;

        final x = _dayLabelWidth + w * (_cellSize + _cellGap);
        final y = d * (_cellSize + _cellGap);
        final count = counts[DateTime(date.year, date.month, date.day)] ?? 0;

        final isSelected = selectedDate != null &&
            date.year == selectedDate!.year &&
            date.month == selectedDate!.month &&
            date.day == selectedDate!.day;

        final fillColor = _getColor(count);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, _cellSize, _cellSize),
          const Radius.circular(3),
        );

        canvas.drawRRect(rect, Paint()..color = fillColor);

        if (isSelected) {
          canvas.drawRRect(
            rect,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }
  }

  Color _getColor(int count) {
    if (count == 0) return Colors.white.withOpacity(0.03);
    if (count <= 2) return accent.withOpacity(0.15);
    if (count <= 5) return accent.withOpacity(0.35);
    if (count <= 10) return accent.withOpacity(0.55);
    return accent.withOpacity(0.8);
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) =>
      old.counts != counts || old.selectedDate != selectedDate || old.accent != accent;
}
