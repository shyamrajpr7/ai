import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/smart_reminder.dart';
import '../providers/reminder_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedTime = DateTime.now().add(const Duration(hours: 1));
  String _selectedRepeat = 'none';
  String _selectedCategory = 'personal';

  static const _categories = ['personal', 'work', 'health', 'learning', 'social'];
  static const _repeats = ['none', 'daily', 'weekly', 'monthly'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Smart Reminders',
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
        child: Consumer<ReminderProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                const SizedBox(height: 100),
                _buildStatsRow(provider, accent),
                const SizedBox(height: 12),
                _buildFilterChips(provider, accent),
                const SizedBox(height: 8),
                Expanded(
                  child: provider.filteredReminders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.alarm_off, size: 64, color: accent.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                provider.filter == 'all'
                                    ? 'No reminders yet'
                                    : 'No ${provider.filter} reminders',
                                style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: provider.filteredReminders.length,
                          itemBuilder: (context, index) {
                            return _buildReminderCard(provider.filteredReminders[index], accent);
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

  Widget _buildStatsRow(ReminderProvider provider, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard('${provider.pendingReminders.length}', 'Pending', accent),
          const SizedBox(width: 10),
          _statCard('${provider.overdueCount}', 'Overdue', const Color(0xFFFF5252)),
          const SizedBox(width: 10),
          _statCard(
            '${provider.reminders.where((r) => r.isCompleted).length}',
            'Done',
            const Color(0xFF00E676),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: color),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ReminderProvider provider, Color accent) {
    final filters = ['all', 'pending', 'overdue', 'completed'];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((f) {
          final selected = provider.filter == f;
          return GestureDetector(
            onTap: () => provider.setFilter(f),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? accent.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
              ),
              child: Text(
                f[0].toUpperCase() + f.substring(1),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: selected ? accent : Colors.white60,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReminderCard(SmartReminder reminder, Color accent) {
    final isOverdue = reminder.isOverdue;
    final borderColor = isOverdue
        ? const Color(0xFFFF5252).withOpacity(0.3)
        : reminder.isCompleted
            ? const Color(0xFF00E676).withOpacity(0.2)
            : Colors.white.withOpacity(0.06);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: reminder.isCompleted
            ? Colors.white.withOpacity(0.02)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<ReminderProvider>().toggleComplete(reminder.id);
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reminder.isCompleted
                    ? const Color(0xFF00E676).withOpacity(0.2)
                    : isOverdue
                        ? const Color(0xFFFF5252).withOpacity(0.15)
                        : Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: reminder.isCompleted
                      ? const Color(0xFF00E676)
                      : isOverdue
                          ? const Color(0xFFFF5252).withOpacity(0.5)
                          : Colors.white.withOpacity(0.15),
                  width: 2,
                ),
              ),
              child: reminder.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Color(0xFF00E676))
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: reminder.isCompleted ? Colors.white38 : Colors.white,
                    decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (reminder.description != null && reminder.description!.isNotEmpty)
                  Text(
                    reminder.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning_amber : Icons.access_time,
                      size: 12,
                      color: isOverdue ? const Color(0xFFFF5252) : Colors.white30,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(reminder.reminderTime),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isOverdue ? const Color(0xFFFF5252) : Colors.white38,
                      ),
                    ),
                    if (reminder.repeatType != 'none') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          reminder.repeatType,
                          style: GoogleFonts.inter(fontSize: 9, color: accent),
                        ),
                      ),
                    ],
                    if (reminder.category != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          reminder.category!,
                          style: GoogleFonts.inter(fontSize: 9, color: Colors.white38),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: Colors.white.withOpacity(0.3)),
            onSelected: (v) {
              if (v == 'edit') _showEditDialog(context, accent, reminder);
              if (v == 'delete') _confirmDelete(context, reminder);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            color: const Color(0xFF1A1A2E),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, Color accent) {
    _titleController.clear();
    _descController.clear();
    _selectedTime = DateTime.now().add(const Duration(hours: 1));
    _selectedRepeat = 'none';
    _selectedCategory = 'personal';
    _showReminderDialog(context, accent, title: 'New Reminder');
  }

  void _showEditDialog(BuildContext context, Color accent, SmartReminder reminder) {
    _titleController.text = reminder.title;
    _descController.text = reminder.description ?? '';
    _selectedTime = reminder.reminderTime;
    _selectedRepeat = reminder.repeatType;
    _selectedCategory = reminder.category ?? 'personal';
    _showReminderDialog(context, accent, title: 'Edit Reminder');
  }

  void _showReminderDialog(BuildContext context, Color accent, {required String title}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _saveReminder(context);
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
                      decoration: InputDecoration(
                        hintText: 'Reminder title...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Description (optional)...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDateTimePicker(setModalState, accent),
                    const SizedBox(height: 16),
                    _buildRepeatPicker(setModalState, accent),
                    const SizedBox(height: 16),
                    _buildCategoryPicker(setModalState, accent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(StateSetter setModalState, Color accent) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedTime,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (c, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.dark(primary: accent, surface: const Color(0xFF1A1A2E))), child: child!),
        );
        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_selectedTime),
            builder: (c, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.dark(primary: accent, surface: const Color(0xFF1A1A2E))), child: child!),
          );
          if (time != null) {
            setModalState(() {
              _selectedTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: accent, size: 20),
            const SizedBox(width: 12),
            Text(
              _formatDateTime(_selectedTime),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.white30, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatPicker(StateSetter setModalState, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repeat', style: GoogleFonts.inter(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: _repeats.map((r) {
            final selected = _selectedRepeat == r;
            return Expanded(
              child: GestureDetector(
                onTap: () => setModalState(() => _selectedRepeat = r),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? accent.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
                  ),
                  child: Center(
                    child: Text(
                      r[0].toUpperCase() + r.substring(1),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: selected ? accent : Colors.white60,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker(StateSetter setModalState, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: GoogleFonts.inter(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((c) {
            final selected = _selectedCategory == c;
            return GestureDetector(
              onTap: () => setModalState(() => _selectedCategory = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? accent.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
                ),
                child: Text(
                  c[0].toUpperCase() + c.substring(1),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: selected ? accent : Colors.white60,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _saveReminder(BuildContext context) {
    if (_titleController.text.trim().isEmpty) return;
    context.read<ReminderProvider>().addReminder(
      title: _titleController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      reminderTime: _selectedTime,
      repeatType: _selectedRepeat,
      category: _selectedCategory,
    );
  }

  void _confirmDelete(BuildContext context, SmartReminder reminder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Reminder?'),
        content: Text(
          'This will permanently delete "${reminder.title}".',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              context.read<ReminderProvider>().deleteReminder(reminder.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $hour:$min $ampm';
  }
}
