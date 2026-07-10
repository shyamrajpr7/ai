import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/reading_item.dart';
import '../services/hive_service.dart';

const _uuid = Uuid();

class ReadingListProvider extends ChangeNotifier {
  final HiveService _hiveService;

  List<ReadingItem> _items = [];
  bool _initialized = false;
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  String _searchQuery = '';

  List<ReadingItem> get items => _items;
  bool get initialized => _initialized;
  String get statusFilter => _statusFilter;
  String get typeFilter => _typeFilter;
  String get searchQuery => _searchQuery;

  List<ReadingItem> get filteredItems {
    var result = _items;
    if (_statusFilter != 'all') {
      result = result.where((i) => i.status == _statusFilter).toList();
    }
    if (_typeFilter != 'all') {
      result = result.where((i) => i.type == _typeFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((i) =>
          i.title.toLowerCase().contains(q) ||
          (i.author?.toLowerCase().contains(q) ?? false) ||
          i.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }
    return result..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  int get toReadCount => _items.where((i) => i.status == 'to_read').length;
  int get readingCount => _items.where((i) => i.status == 'reading').length;
  int get completedCount => _items.where((i) => i.status == 'completed').length;
  double get averageRating {
    final rated = _items.where((i) => i.rating != null).toList();
    if (rated.isEmpty) return 0;
    return rated.fold(0.0, (sum, i) => sum + i.rating!) / rated.length;
  }

  ReadingListProvider(this._hiveService);

  Future<void> load() async {
    _items = _hiveService.loadReadingItems();
    _initialized = true;
    notifyListeners();
  }

  Future<void> addItem({
    required String title,
    String? author,
    String? url,
    String type = 'book',
  }) async {
    final item = ReadingItem(
      id: _uuid.v4(),
      title: title,
      author: author,
      url: url,
      type: type,
    );
    _items.add(item);
    await _save();
    notifyListeners();
  }

  Future<void> updateItem(ReadingItem updated) async {
    final idx = _items.indexWhere((i) => i.id == updated.id);
    if (idx != -1) {
      _items[idx] = updated;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> updateProgress(String id, int progress) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _items[idx].progress = progress.clamp(0, 100);
      _items[idx].updatedAt = DateTime.now();
      if (progress >= 100) {
        _items[idx].status = 'completed';
      } else if (progress > 0 && _items[idx].status == 'to_read') {
        _items[idx].status = 'reading';
      }
      await _save();
      notifyListeners();
    }
  }

  Future<void> setRating(String id, int rating) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _items[idx].rating = rating;
      _items[idx].updatedAt = DateTime.now();
      await _save();
      notifyListeners();
    }
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setTypeFilter(String filter) {
    _typeFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> _save() async {
    await _hiveService.saveReadingItems(_items);
  }
}
