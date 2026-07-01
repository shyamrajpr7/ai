import 'package:flutter/material.dart';
import '../services/hive_service.dart';

enum BackendType { groq, ollama }

class SettingsProvider extends ChangeNotifier {
  final HiveService _hiveService;

  Color _accentColor = const Color(0xFF7C4DFF);
  BackendType _backend = BackendType.groq;
  String _groqModel = 'llama3-70b-8192';
  String _ollamaEndpoint = 'http://localhost:11434/v1';
  String _ollamaModel = 'llama3.2';
  bool _initialized = false;

  Color get accentColor => _accentColor;
  BackendType get backend => _backend;
  String get groqModel => _groqModel;
  String get ollamaEndpoint => _ollamaEndpoint;
  String get ollamaModel => _ollamaModel;
  bool get initialized => _initialized;

  SettingsProvider(this._hiveService);

  Future<void> load() async {
    final data = _hiveService.loadSettings();
    if (data != null) {
      _accentColor = Color(data['accentColor'] as int);
      _backend = BackendType.values[data['backend'] as int];
      _groqModel = data['groqModel'] as String? ?? 'llama3-70b-8192';
      _ollamaEndpoint =
          data['ollamaEndpoint'] as String? ?? 'http://localhost:11434/v1';
      _ollamaModel = data['ollamaModel'] as String? ?? 'llama3.2';
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _save();
    notifyListeners();
  }

  Future<void> setBackend(BackendType type) async {
    _backend = type;
    await _save();
    notifyListeners();
  }

  Future<void> setGroqModel(String model) async {
    _groqModel = model;
    await _save();
    notifyListeners();
  }

  Future<void> setOllamaEndpoint(String endpoint) async {
    _ollamaEndpoint = endpoint;
    await _save();
    notifyListeners();
  }

  Future<void> setOllamaModel(String model) async {
    _ollamaModel = model;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _hiveService.saveSettings({
      'accentColor': _accentColor.value,
      'backend': _backend.index,
      'groqModel': _groqModel,
      'ollamaEndpoint': _ollamaEndpoint,
      'ollamaModel': _ollamaModel,
    });
  }
}
