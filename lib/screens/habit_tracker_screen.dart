import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/settings_provider.dart';
import '../models/habit.dart';
import '../widgets/gradient_mesh_background.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HabitProvider>();
      if (provider.habits.isNotEmpty && provider.coachMessages.isEmpty) {
        provider.generateCoachMessage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showAddHabitDialog() {
    final accent = context.read<SettingsProvider>().accentColor;
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    String emoji = '🎯';
    String category = 'other';
    int colorValue = 0xFF7C4DFF;

    final emojis = ['🎯', '💪', '📚', '🧠', '🏃', '🧘', '🎨', '✍️', '🥗', '💧', '🌱', '🎵', '🧹', '📝', '☀️', '🌙'];
    final categories = [
      'health', 'fitness', 'learning', 'mindfulness', 'productivity', 'creative', 'other'
    ];
    final colors = [
      0xFF7C4DFF, 0xFF00E676, 0xFF448AFF, 0xFFFF5252, 0xFFFF8A65, 0xFFE040FB, 0xFFFFD740,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: accent.withOpacity(0.2))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text('New Habit', style: TextStyle(
                  color: Colors.white, fontSize: 18,
                  fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold,
                )),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: titleCtl,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Habit name...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: descCtl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Optional description...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Icon', style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: emojis.map((e) {
                    final sel = e == emoji;
                    return GestureDetector(
                      onTap: () => setSheetState(() => emoji = e),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                          border: sel ? Border.all(color: accent, width: 2) : null,
                        ),
                        child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Category', style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((c) {
                    final sel = c == category;
                    return GestureDetector(
                      onTap: () => setSheetState(() => category = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: sel ? Border.all(color: accent) : Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Text(
                          c[0].toUpperCase() + c.substring(1),
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.white.withOpacity(0.5),
                            fontSize: 13, fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Color', style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: colors.map((c) {
                    final sel = c == colorValue;
                    return GestureDetector(
                      onTap: () => setSheetState(() => colorValue = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(c),
                          border: sel ? Border.all(color: Colors.white, width: 2.5) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {
                    if (titleCtl.text.trim().isEmpty) return;
                    final habit = Habit(
                      id: const Uuid().v4(),
                      title: titleCtl.text.trim(),
                      description: descCtl.text.trim(),
                      emoji: emoji,
                      category: category,
                      colorValue: colorValue,
                    );
                    context.read<HabitProvider>().addHabit(habit);
                    Navigator.pop(ctx);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('Create Habit', style: TextStyle(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w600,
                      )),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(Habit habit) {
    final accent = context.read<SettingsProvider>().accentColor;
    final titleCtl = TextEditingController(text: habit.title);
    final descCtl = TextEditingController(text: habit.description);
    String emoji = habit.emoji;
    String category = habit.category;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: accent.withOpacity(0.2))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2)),
              )),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text('Edit Habit', style: TextStyle(
                  color: Colors.white, fontSize: 18,
                  fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold,
                )),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: titleCtl,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Habit name...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: descCtl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Description...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await context.read<HabitProvider>().deleteHabit(habit.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withOpacity(0.2)),
                          ),
                          child: Center(child: Text('Delete', style: TextStyle(
                            color: Colors.red.shade300, fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (titleCtl.text.trim().isEmpty) return;
                          habit.title = titleCtl.text.trim();
                          habit.description = descCtl.text.trim();
                          habit.emoji = emoji;
                          habit.category = category;
                          context.read<HabitProvider>().updateHabit(habit);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(child: Text('Save', style: TextStyle(
                            color: Colors.white, fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final provider = context.watch<HabitProvider>();

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
                  gradient: LinearGradient(colors: [accent, const Color(0xFFFF8A65)]),
                ),
                child: const Center(child: Icon(Icons.repeat, size: 17, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              const Text('Habit Tracker', style: TextStyle(
                color: Colors.white, fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold, fontSize: 20,
              )),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.add_rounded, color: Colors.white.withOpacity(0.6)),
              onPressed: _showAddHabitDialog,
              tooltip: 'Add habit',
            ),
          ],
        ),
        body: provider.habits.isEmpty
            ? _buildEmptyState(accent, provider)
            : _buildDashboard(accent, provider),
      ),
    );
  }

  Widget _buildEmptyState(Color accent, HabitProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [accent.withOpacity(0.12), accent.withOpacity(0.03)]),
            ),
            child: Icon(Icons.repeat, size: 40, color: accent.withOpacity(0.3)),
          ),
          const SizedBox(height: 24),
          Text('Habit Tracker', style: TextStyle(
            color: Colors.white.withOpacity(0.6), fontSize: 18,
            fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w500,
          )),
          const SizedBox(height: 8),
          Text('Build streaks with AI-powered coaching', style: TextStyle(
            color: Colors.white.withOpacity(0.25), fontSize: 14, fontFamily: 'Inter',
          )),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _showAddHabitDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, const Color(0xFFFF8A65)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Add Your First Habit', style: TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter',
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(Color accent, HabitProvider provider) {
    final hasCoach = provider.coachMessages.isNotEmpty;
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        _buildHeader(accent, provider),
        const SizedBox(height: 12),
        if (hasCoach || provider.isGeneratingCoach)
          _buildCoachSection(accent, provider),
        const SizedBox(height: 8),
        ...provider.habits.map((habit) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildHabitCard(accent, provider, habit),
        )),
      ],
    );
  }

  Widget _buildHeader(Color accent, HabitProvider provider) {
    final rate = provider.globalCompletionRate;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Global Streak', style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 22, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      '${provider.globalStreak}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9), fontSize: 28,
                        fontWeight: FontWeight.bold, fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('days', style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 14, fontFamily: 'Inter',
                    )),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('30-Day Rate', style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 4),
              Text(
                '${(rate * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: rate > 0.7 ? const Color(0xFF00E676) : rate > 0.4 ? Colors.orange : Colors.red.shade300,
                  fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoachSection(Color accent, HabitProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: accent),
              const SizedBox(width: 6),
              Text('AI Coach', style: TextStyle(
                color: accent, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'SpaceGrotesk',
              )),
              const Spacer(),
              if (!provider.isGeneratingCoach)
                GestureDetector(
                  onTap: () => provider.generateCoachMessage(),
                  child: Icon(Icons.refresh_rounded, size: 16, color: Colors.white.withOpacity(0.4)),
                ),
              if (provider.isGeneratingCoach)
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: accent)),
            ],
          ),
          const SizedBox(height: 10),
          if (provider.coachMessages.isNotEmpty)
            Text(
              provider.coachMessages.first.content,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 13,
                fontFamily: 'Inter', height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Color accent, HabitProvider provider, Habit habit) {
    final color = Color(habit.colorValue);
    final done = habit.isCompletedOn(DateTime.now());
    final streak = habit.currentStreak;
    final rate = habit.completionRate(30);
    final weekly = provider.getWeeklyData(habit.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? color.withOpacity(0.2) : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => provider.toggleLog(habit.id),
            onLongPress: () => _showEditDialog(habit),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                      border: Border.all(color: done ? color.withOpacity(0.3) : Colors.white.withOpacity(0.06)),
                    ),
                    child: Center(child: Text(habit.emoji, style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.title, style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 15,
                          fontWeight: FontWeight.w600, fontFamily: 'Inter',
                        )),
                        if (habit.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(habit.description, style: TextStyle(
                            color: Colors.white.withOpacity(0.35), fontSize: 12, fontFamily: 'Inter',
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department, size: 14, color: streak > 0 ? Colors.orange : Colors.white.withOpacity(0.2)),
                          const SizedBox(width: 3),
                          Text('$streak', style: TextStyle(
                            color: streak > 0 ? Colors.orange : Colors.white.withOpacity(0.3),
                            fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'SpaceGrotesk',
                          )),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${(rate * 100).toStringAsFixed(0)}%', style: TextStyle(
                        color: Colors.white.withOpacity(0.3), fontSize: 11,
                      )),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? color : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: done ? color : Colors.white.withOpacity(0.15),
                        width: 2,
                      ),
                    ),
                    child: done
                        ? Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.04))),
            ),
            child: Row(
              children: weekly.map((day) {
                final isToday = DateTime.now().day == (day['date'] as DateTime).day;
                final completed = day['completed'] as bool;
                return Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed
                            ? color.withOpacity(0.6)
                            : Colors.white.withOpacity(0.04),
                        border: isToday
                            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)
                            : null,
                      ),
                      child: completed
                          ? Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class Uuid {
  const Uuid();
  String v4() {
    final r = Random();
    return '${_hex(r, 8)}-${_hex(r, 4)}-4${_hex(r, 3)}-${_hex(r, 4)}-${_hex(r, 12)}';
  }
  String _hex(Random r, int digits) {
    final chars = '0123456789abcdef';
    return List.generate(digits, (_) => chars[r.nextInt(16)]).join();
  }
}
