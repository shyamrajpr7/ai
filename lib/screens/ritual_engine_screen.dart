import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ritual.dart';
import '../providers/ritual_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class RitualEngineScreen extends StatefulWidget {
  const RitualEngineScreen({super.key});

  @override
  State<RitualEngineScreen> createState() => _RitualEngineScreenState();
}

class _RitualEngineScreenState extends State<RitualEngineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RitualProvider>().load();
    });
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
              Expanded(
                child: Consumer<RitualProvider>(
                  builder: (context, provider, _) {
                    if (!provider.initialized) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    if (provider.isGenerating) {
                      return _buildGeneratingState(accent);
                    }
                    if (!provider.hasTodayRituals) {
                      return _buildEmptyState(accent, provider);
                    }
                    return _buildRitualsList(accent, provider);
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
    final provider = context.watch<RitualProvider>();
    final now = DateTime.now();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dayNames = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    final dateStr =
        '${dayNames[now.weekday - 1]}, ${monthNames[now.month - 1]} ${now.day}';

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
          child: Column(
            children: [
              Row(
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
                    child: const Icon(Icons.self_improvement,
                        size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ritual Engine',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const Spacer(),
                  if (provider.hasTodayRituals)
                    GestureDetector(
                      onTap: () => _confirmReset(context, provider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.refresh_rounded,
                            size: 16, color: Colors.white.withOpacity(0.4)),
                      ),
                    ),
                  const SizedBox(width: 4),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 52, bottom: 6),
                child: Row(
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    const Spacer(),
                    if (provider.currentStreak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: accent.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department,
                                size: 12, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              '${provider.currentStreak}-day streak',
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color accent, RitualProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.1),
              ),
              child: Icon(
                Icons.self_improvement,
                size: 32,
                color: accent.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Rituals Today',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate personalized daily challenges,\njournal prompts & habits from your conversations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            _AccentButton(
              label: 'Generate Today\'s Rituals',
              accent: accent,
              icon: Icons.auto_awesome,
              onTap: () => provider.generateDailyRituals(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingState(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Crafting your rituals...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRitualsList(Color accent, RitualProvider provider) {
    final rituals = provider.todayRituals;
    if (rituals.isEmpty) return const SizedBox.shrink();

    final challenge = rituals.where((r) => r.type == 'challenge').firstOrNull;
    final journal = rituals.where((r) => r.type == 'journal').firstOrNull;
    final habit = rituals.where((r) => r.type == 'habit').firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (challenge != null) _buildChallengeCard(accent, provider, challenge),
        if (challenge != null && journal != null) const SizedBox(height: 12),
        if (journal != null) _buildJournalCard(accent, provider, journal),
        if (journal != null && habit != null) const SizedBox(height: 12),
        if (habit != null) _buildHabitCard(accent, provider, habit),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Come back tomorrow for new rituals',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 11,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(
      Color accent, RitualProvider provider, Ritual challenge) {
    return _RitualCard(
      accent: accent,
      icon: Icons.emoji_events_rounded,
      title: 'Daily Challenge',
      typeLabel: 'challenge',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  provider.toggleComplete(challenge.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: challenge.completed
                        ? accent
                        : Colors.transparent,
                    border: Border.all(
                      color: challenge.completed
                          ? accent
                          : Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: challenge.completed
                      ? const Icon(Icons.check,
                          size: 16, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (challenge.completed) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      size: 14, color: Colors.green.withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJournalCard(
      Color accent, RitualProvider provider, Ritual journal) {
    final ctrl = TextEditingController(text: journal.journalResponse ?? '');
    final hasContent = journal.journalResponse != null &&
        journal.journalResponse!.trim().isNotEmpty;

    return _RitualCard(
      accent: accent,
      icon: Icons.edit_note_rounded,
      title: 'Journal Prompt',
      typeLabel: 'journal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            journal.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            journal.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withOpacity(0.06)),
            ),
            child: TextField(
              controller: ctrl,
              maxLines: 4,
              minLines: 2,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.4),
              decoration: InputDecoration(
                hintText: 'Write your thoughts...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (value) {
                provider.saveJournalResponse(journal.id, value);
              },
            ),
          ),
          if (hasContent) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check,
                      size: 14, color: accent.withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Text(
                    'Saved',
                    style: TextStyle(
                      color: accent.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHabitCard(
      Color accent, RitualProvider provider, Ritual habit) {
    return _RitualCard(
      accent: accent,
      icon: Icons.repeat_rounded,
      title: 'Daily Habit',
      typeLabel: 'habit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      habit.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  provider.toggleComplete(habit.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: habit.completed
                        ? accent
                        : Colors.transparent,
                    border: Border.all(
                      color: habit.completed
                          ? accent
                          : Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: habit.completed
                      ? const Icon(Icons.check,
                          size: 16, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.local_fire_department,
                  size: 14, color: Colors.orange.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text(
                'Streak: ${habit.streak} days',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: habit.completed
                      ? Colors.green.withOpacity(0.12)
                      : accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  habit.completed ? 'Done Today' : 'Mark Complete',
                  style: TextStyle(
                    color: habit.completed
                        ? Colors.green.withOpacity(0.7)
                        : accent.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, RitualProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Regenerate Rituals?'),
        content: Text(
          'This will replace today\'s rituals with new ones.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
              Navigator.pop(ctx);
              provider.generateDailyRituals();
            },
            child: const Text(
              'Regenerate',
              style: TextStyle(color: Color(0xFF7C4DFF)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentButton extends StatelessWidget {
  final String label;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  const _AccentButton({
    required this.label,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String typeLabel;
  final Widget child;

  const _RitualCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.typeLabel,
    required this.child,
  });

  Color _typeColor(String type) {
    switch (type) {
      case 'challenge':
        return const Color(0xFFFFD700);
      case 'journal':
        return const Color(0xFF64FFDA);
      case 'habit':
        return const Color(0xFFFF8A65);
      default:
        return accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(typeLabel);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: typeColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: typeColor.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}
