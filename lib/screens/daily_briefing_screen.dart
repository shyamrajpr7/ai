import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/daily_briefing.dart';
import '../providers/daily_briefing_provider.dart';
import '../providers/settings_provider.dart';
import '../models/mood_analytics.dart';
import '../widgets/gradient_mesh_background.dart';

class DailyBriefingScreen extends StatefulWidget {
  const DailyBriefingScreen({super.key});

  @override
  State<DailyBriefingScreen> createState() => _DailyBriefingScreenState();
}

class _DailyBriefingScreenState extends State<DailyBriefingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DailyBriefingProvider>();
      if (provider.todayBriefing == null) {
        provider.generateBriefing();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Daily Briefing',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<DailyBriefingProvider>().generateBriefing();
            },
          ),
        ],
      ),
      body: GradientMeshBackground(
        child: Consumer<DailyBriefingProvider>(
          builder: (context, provider, _) {
            if (provider.isGenerating && provider.todayBriefing == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Building your briefing...',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }

            final briefing = provider.todayBriefing;
            if (briefing == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wb_sunny_outlined,
                      size: 64,
                      color: accent.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No briefing yet',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        provider.generateBriefing();
                      },
                      child: Text(
                        'Generate Briefing',
                        style: TextStyle(color: accent),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.generateBriefing(),
              color: accent,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 32),
                children: [
                  _buildGreetingSection(context, briefing, accent),
                  const SizedBox(height: 20),
                  _buildCompletionRing(context, briefing, accent),
                  const SizedBox(height: 20),
                  _buildHabitsSection(context, briefing, accent),
                  const SizedBox(height: 20),
                  _buildRitualsSection(context, briefing, accent),
                  const SizedBox(height: 20),
                  if (briefing.moodTrend != null) ...[
                    _buildMoodSection(context, briefing.moodTrend!, accent),
                    const SizedBox(height: 20),
                  ],
                  if (briefing.flashCardsDue.isNotEmpty) ...[
                    _buildFlashCardsSection(context, briefing.flashCardsDue, accent),
                    const SizedBox(height: 20),
                  ],
                  _buildInsightSection(context, provider, accent),
                  const SizedBox(height: 20),
                  _buildHistorySection(context, provider, accent),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGreetingSection(
      BuildContext context, DailyBriefing briefing, Color accent) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.15),
            accent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting!',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(briefing.date)} \u2022 ${briefing.totalConversationsToday} conversations today',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRing(
      BuildContext context, DailyBriefing briefing, Color accent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: briefing.completionRate,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      briefing.completionRate >= 0.7
                          ? const Color(0xFF00E676)
                          : briefing.completionRate >= 0.4
                              ? accent
                              : const Color(0xFFFFD740),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${(briefing.completionRate * 100).toInt()}%',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Progress',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${briefing.completedHabits}/${briefing.totalHabits} habits \u2022 ${briefing.completedRituals}/${briefing.totalRituals} rituals',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsSection(
      BuildContext context, DailyBriefing briefing, Color accent) {
    if (briefing.habits.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Habits',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${briefing.completedHabits}/${briefing.totalHabits}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...briefing.habits.map((h) => _buildHabitTile(h, accent)),
        ],
      ),
    );
  }

  Widget _buildHabitTile(HabitSummary habit, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: habit.completed
            ? accent.withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: habit.completed
              ? accent.withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Text(habit.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    decoration: habit.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (habit.currentStreak > 0)
                  Text(
                    '${habit.currentStreak} day streak',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: accent.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            habit.completed
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: habit.completed ? accent : Colors.white38,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildRitualsSection(
      BuildContext context, DailyBriefing briefing, Color accent) {
    if (briefing.rituals.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.self_improvement, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Rituals',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${briefing.completedRituals}/${briefing.totalRituals}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...briefing.rituals.map((r) => _buildRitualTile(r, accent)),
        ],
      ),
    );
  }

  Widget _buildRitualTile(RitualSummary ritual, Color accent) {
    final icon = ritual.type == 'challenge'
        ? Icons.emoji_events_outlined
        : ritual.type == 'journal'
            ? Icons.edit_note
            : Icons.psychology_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ritual.completed
            ? accent.withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ritual.completed
              ? accent.withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: ritual.completed ? accent : Colors.white54,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ritual.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                decoration:
                    ritual.completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Icon(
            ritual.completed
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: ritual.completed ? accent : Colors.white38,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection(
      BuildContext context, MoodTrend mood, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mood_outlined, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mood Trend',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                MoodColor.emojiForMood(mood.dominantMood),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mood.dominantMood[0].toUpperCase() +
                          mood.dominantMood.substring(1),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: MoodColor.forMood(mood.dominantMood),
                      ),
                    ),
                    Text(
                      'Based on ${mood.entryCount} conversations',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMoodMetric('Sentiment', mood.avgSentiment, accent),
              const SizedBox(width: 16),
              _buildMoodMetric('Energy', mood.avgEnergy, accent),
            ],
          ),
          if (mood.topTopics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: mood.topTopics.take(5).map((topic) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    topic,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: accent,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodMetric(String label, double value, Color accent) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 10,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${value.toStringAsFixed(1)}/10',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashCardsSection(
      BuildContext context, List<FlashCardDue> cards, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style_outlined, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Flash Cards Due',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cards.length}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...cards.take(5).map((card) {
            final diffColor = card.difficulty == 'hard'
                ? const Color(0xFFFF5252)
                : card.difficulty == 'medium'
                    ? const Color(0xFFFFD740)
                    : const Color(0xFF00E676);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: diffColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${card.difficulty} \u2022 ${card.reviewCount} reviews',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (cards.length > 5)
            Text(
              '...and ${cards.length - 5} more',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightSection(
      BuildContext context, DailyBriefingProvider provider, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Insight',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.isGeneratingInsight)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Generating insight...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ],
            )
          else if (provider.todayBriefing?.aiInsight != null)
            Text(
              provider.todayBriefing!.aiInsight!,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.5,
                color: Colors.white.withOpacity(0.85),
              ),
            )
          else
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                provider.generateAiInsight();
              },
              icon: Icon(Icons.auto_awesome, size: 18, color: accent),
              label: Text(
                'Generate AI Insight',
                style: TextStyle(color: accent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(
      BuildContext context, DailyBriefingProvider provider, Color accent) {
    if (provider.history.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Briefings',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...provider.history.skip(1).take(7).map((b) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: b.completionRate,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        b.completionRate >= 0.7
                            ? const Color(0xFF00E676)
                            : accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(b.date),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${b.completedHabits + b.completedRituals}/${b.totalHabits + b.totalRituals} completed',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(0.06),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
