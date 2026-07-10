import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/smart_reminder.dart';
import '../services/hive_service.dart';

const _uuid = Uuid();

class ReminderProvider extends ChangeNotifier {
  final HiveService _hiveService;

  List<SmartReminder> _reminders = [];
  bool _initialized = false;
  String _filter = 'all';

  List<SmartReminder> get reminders => _reminders;
  bool get initialized => _initialized;
  String get filter => _filter;

  List<SmartReminder> get filteredReminders {
    switch (_filter) {
      case 'pending':
        return _reminders.where((r) => !r.isCompleted).toList();
      case 'completed':
        return _reminders.where((r) => r.isCompleted).toList();
      case 'overdue':
        return _reminders.where((r) => r.isOverdue).toList();
      default:
        return _reminders;
    }
  }

  List<SmartReminder> get pendingReminders =>
      _reminders.where((r) => !r.isCompleted).toList();

  int get overdueCount =>
      _reminders.where((r) => r.isOverdue).length;

  Map<String, List<SmartReminder>> get byCategory {
    final map = <String, List<SmartReminder>>{};
    for (final r in _reminders) {
      final cat = r.category ?? 'uncategorized';
      map.putIfAbsent(cat, () => []).add(r);
    }
    return map;
  }

  ReminderProvider(this._hiveService);

  Future<void> load() async {
    _reminders = _hiveService.loadSmartReminders();
    _initialized = true;
    notifyListeners();
  }

  Future<void> addReminder({
    required String title,
    String? description,
    required DateTime reminderTime,
    String repeatType = 'none',
    String? category,
  }) async {
    final reminder = SmartReminder(
      id: _uuid.v4(),
      title: title,
      description: description,
      reminderTime: reminderTime,
      repeatType: repeatType,
      category: category,
    );
    _reminders.add(reminder);
    await _save();
    notifyListeners();
  }

  Future<void> updateReminder(SmartReminder updated) async {
    final idx = _reminders.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      _reminders[idx] = updated;
      await _save();
      notifyListeners();
    }
  }

  Future<void> toggleComplete(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx].isCompleted = !_reminders[idx].isCompleted;
      await _save();
      notifyListeners();
    }
  }

  Future<void> toggleEnabled(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx].isEnabled = !_reminders[idx].isEnabled;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _save();
    notifyListeners();
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> _save() async {
    await _hiveService.saveSmartReminders(_reminders);
  }
}
