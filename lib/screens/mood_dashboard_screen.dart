import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/mood_analytics.dart';
import '../providers/mood_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class MoodDashboardScreen extends StatefulWidget {
  const MoodDashboardScreen({super.key});

  @override
  State<MoodDashboardScreen> createState() => _MoodDashboardScreenState();
}

class _MoodDashboardScreenState extends State<MoodDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MoodProvider>();
      if (provider.entries.isEmpty && !provider.isAnalyzing) {
        final chatProvider = context.read<ChatProvider>();
        provider.analyzeConversations(chatProvider.conversations);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final moodProvider = context.watch<MoodProvider>();
    final summary = moodProvider.weeklySummary;

    return GradientMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: Colors.white.withOpacity(0.6)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Icon(Icons.insights, size: 20, color: accent),
              const SizedBox(width: 10),
              const Text(
                'Mood Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: accent),
              onPressed: () {
                final chatProvider = context.read<ChatProvider>();
                moodProvider.analyzeConversations(chatProvider.conversations);
              },
              tooltip: 'Analyze conversations',
            ),
          ],
        ),
        body: moodProvider.isAnalyzing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF7C4DFF)),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing conversations...',
                      style: TextStyle(
                        color: Colors.white54,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ],
                ),
              )
            : moodProvider.entries.isEmpty
                ? _emptyState(accent)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _weeklyMoodCard(accent, summary),
                        const SizedBox(height: 16),
                        _sentimentChart(accent, moodProvider),
                        const SizedBox(height: 16),
                        _topicCloud(accent, moodProvider),
                        const SizedBox(height: 16),
                        _cognitiveMap(accent, moodProvider),
                        const SizedBox(height: 16),
                        _recentMoods(accent, moodProvider),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _emptyState(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights, size: 64, color: accent.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No mood data yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap refresh to analyze your conversations',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final chatProvider = context.read<ChatProvider>();
              final moodProvider = context.read<MoodProvider>();
              moodProvider.analyzeConversations(chatProvider.conversations);
            },
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Analyze Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeklyMoodCard(Color accent, MoodSummary? summary) {
    if (summary == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Text(
          'No data for this week',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontFamily: 'Inter',
          ),
        ),
      );
    }

    final moodColor = MoodColor.forMood(summary.dominantMood);
    final emoji = MoodColor.emojiForMood(summary.dominantMood);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            moodColor.withOpacity(0.15),
            moodColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: moodColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Week\'s Vibe',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      summary.dominantMood.toUpperCase(),
                      style: TextStyle(
                        color: moodColor,
                        fontSize: 24,
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${summary.conversationCount} chats',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBar('Sentiment', summary.avgSentiment, moodColor),
              const SizedBox(width: 12),
              _statBar('Energy', summary.avgEnergy, accent),
            ],
          ),
          if (summary.topTopics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: summary.topTopics.take(5).map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: moodColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: moodColor.withOpacity(0.2)),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    color: moodColor.withOpacity(0.8),
                    fontSize: 11,
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBar(String label, double value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 10,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${value.toStringAsFixed(1)}/10',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sentimentChart(Color accent, MoodProvider provider) {
    final weekly = provider.weeklyHistory.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'Sentiment Trend',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _SentimentChartPainter(
                summaries: weekly,
                accent: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicCloud(Color accent, MoodProvider provider) {
    final topicCounts = <String, int>{};
    for (final e in provider.entries) {
      for (final t in e.topics) {
        topicCounts[t] = (topicCounts[t] ?? 0) + 1;
      }
    }
    final sorted = topicCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(20).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    final maxCount = top.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_outlined, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'Topic Cloud',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: top.map((e) {
              final ratio = e.value / maxCount;
              final fontSize = 11 + ratio * 15;
              final opacity = 0.4 + ratio * 0.6;
              final moodColor = MoodColor.forMood(e.key);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                },
                child: Text(
                  e.key,
                  style: TextStyle(
                    color: moodColor.withOpacity(opacity),
                    fontSize: fontSize,
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _cognitiveMap(Color accent, MoodProvider provider) {
    final topicPairs = <Set<String>>{};
    final topicCounts = <String, int>{};
    for (final e in provider.entries) {
      for (var i = 0; i < e.topics.length; i++) {
        topicCounts[e.topics[i]] = (topicCounts[e.topics[i]] ?? 0) + 1;
        for (var j = i + 1; j < e.topics.length; j++) {
          topicPairs.add({e.topics[i], e.topics[j]});
        }
      }
    }

    final topTopics = topicCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final nodes = topTopics.take(8).map((e) => e.key).toList();
    if (nodes.isEmpty) return const SizedBox.shrink();

    final nodeColors = nodes.asMap().map((i, n) =>
      MapEntry(n, MoodColor.forMood(n)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_outlined, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'Cognitive Map',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _CognitiveMapPainter(
                nodes: nodes,
                edges: topicPairs,
                nodeColors: nodeColors,
                accent: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentMoods(Color accent, MoodProvider provider) {
    final recent = provider.entries.take(5).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'Recent Conversations',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recent.map((e) => _moodRow(e, accent)),
        ],
      ),
    );
  }

  Widget _moodRow(MoodEntry entry, Color accent) {
    final moodColor = MoodColor.forMood(entry.dominantMood);
    final emoji = MoodColor.emojiForMood(entry.dominantMood);
    final dateStr =
        '${entry.date.month}/${entry.date.day}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.conversationTitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.summary.isNotEmpty)
                  Text(
                    entry.summary,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: moodColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: moodColor.withOpacity(0.2)),
            ),
            child: Text(
              entry.dominantMood,
              style: TextStyle(
                color: moodColor,
                fontSize: 10,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

// -- Painters --

class _SentimentChartPainter extends CustomPainter {
  final List<MoodSummary> summaries;
  final Color accent;

  _SentimentChartPainter({required this.summaries, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    if (summaries.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final count = summaries.length;
    final padding = 24.0;
    final chartW = w - padding * 2;
    final chartH = h - padding * 2;
    final stepX = count > 1 ? chartW / (count - 1) : chartW / 2;

    // grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 4; i++) {
      final y = padding + chartH * (1 - i / 4);
      canvas.drawLine(Offset(padding, y), Offset(w - padding, y), gridPaint);
    }

    // sentiment line
    final linePaint = Paint()
      ..color = accent.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < count; i++) {
      final x = padding + i * stepX;
      final y = padding + chartH * (1 - summaries[i].avgSentiment / 10);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // dots
    for (var i = 0; i < count; i++) {
      final x = padding + i * stepX;
      final y = padding + chartH * (1 - summaries[i].avgSentiment / 10);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = accent);
    }

    // labels
    for (var i = 0; i < count; i++) {
      final x = padding + i * stepX;
      final weekLabel = 'W${i + 1}';
      final tp = TextPainter(
        text: TextSpan(
          text: weekLabel,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 9,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, h - padding + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _SentimentChartPainter oldDelegate) =>
      oldDelegate.summaries != summaries;
}

class _CognitiveMapPainter extends CustomPainter {
  final List<String> nodes;
  final Set<Set<String>> edges;
  final Map<String, Color> nodeColors;
  final Color accent;

  _CognitiveMapPainter({
    required this.nodes,
    required this.edges,
    required this.nodeColors,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(size.width, size.height) * 0.35;
    final positions = <String, Offset>{};

    for (var i = 0; i < nodes.length; i++) {
      final angle = 2 * pi * i / nodes.length - pi / 2;
      positions[nodes[i]] = Offset(
        cx + radius * cos(angle),
        cy + radius * sin(angle),
      );
    }

    // edges
    final edgePaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final edge in edges) {
      final list = edge.toList();
      if (list.length != 2) continue;
      final from = positions[list[0]];
      final to = positions[list[1]];
      if (from == null || to == null) continue;
      edgePaint.color = Colors.white.withOpacity(0.08);
      canvas.drawLine(from, to, edgePaint);
    }

    // nodes
    for (final node in nodes) {
      final pos = positions[node];
      if (pos == null) continue;
      final color = nodeColors[node] ?? accent;
      final r = 16.0;

      canvas.drawCircle(pos, r + 2, Paint()..color = color.withOpacity(0.15));
      canvas.drawCircle(pos, r, Paint()..color = color.withOpacity(0.3));

      final tp = TextPainter(
        text: TextSpan(
          text: node.length > 8 ? '${node.substring(0, 7)}.' : node,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 9,
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _CognitiveMapPainter oldDelegate) =>
      oldDelegate.nodes != nodes;
}
