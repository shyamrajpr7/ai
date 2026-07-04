import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/persona.dart';
import '../services/hive_service.dart';

const _uuid = Uuid();

enum BackendType { groq, ollama, claude }

class SettingsProvider extends ChangeNotifier {
  final HiveService _hiveService;

  Color _accentColor = const Color(0xFF7C4DFF);
  BackendType _backend = BackendType.groq;
  String _groqModel = 'llama-3.1-8b-instant';
  String _ollamaEndpoint = 'http://localhost:11434/v1';
  String _ollamaModel = 'llama3.2';
  String _claudeModel = 'claude-sonnet-4-20250514';
  double _temperature = 0.6;
  bool _webSearchEnabled = false;
  bool _initialized = false;
  List<Persona> _personas = [];
  String _activePersonaId = 'default-assistant';

  Color get accentColor => _accentColor;
  BackendType get backend => _backend;
  String get groqModel => _groqModel;
  String get ollamaEndpoint => _ollamaEndpoint;
  String get ollamaModel => _ollamaModel;
  String get claudeModel => _claudeModel;
  double get temperature => _temperature;
  bool get webSearchEnabled => _webSearchEnabled;
  bool get initialized => _initialized;
  List<Persona> get personas => _personas;

  Persona get activePersona {
    final idx = _personas.indexWhere((p) => p.id == _activePersonaId);
    return idx != -1
        ? _personas[idx]
        : Persona.defaults.first;
  }

  SettingsProvider(this._hiveService);

  Future<void> load() async {
    final data = _hiveService.loadSettings();
    if (data != null) {
      _accentColor = Color(data['accentColor'] as int);
      _backend = BackendType.values[data['backend'] as int];
      _groqModel = data['groqModel'] as String? ?? 'llama-3.1-8b-instant';
      _ollamaEndpoint =
          data['ollamaEndpoint'] as String? ?? 'http://localhost:11434/v1';
      _ollamaModel = data['ollamaModel'] as String? ?? 'llama3.2';
      _claudeModel = data['claudeModel'] as String? ?? 'claude-sonnet-4-20250514';
      _temperature = (data['temperature'] as num?)?.toDouble() ?? 0.6;
      _webSearchEnabled = data['webSearchEnabled'] as bool? ?? false;
      _activePersonaId = data['activePersonaId'] as String? ?? 'default-assistant';
      final personasRaw = data['personas'] as List<dynamic>?;
      if (personasRaw != null) {
        _personas = personasRaw
            .map((e) => Persona.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    if (_personas.isEmpty) {
      _personas = Persona.defaults.map((p) => p.copyWith()).toList();
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

  Future<void> setClaudeModel(String model) async {
    _claudeModel = model;
    await _save();
    notifyListeners();
  }

  Future<void> setTemperature(double value) async {
    _temperature = value;
    await _save();
    notifyListeners();
  }

  Future<void> setWebSearchEnabled(bool enabled) async {
    _webSearchEnabled = enabled;
    await _save();
    notifyListeners();
  }

  Future<void> setActivePersona(String id) async {
    _activePersonaId = id;
    await _save();
    notifyListeners();
  }

  Future<void> addPersona(Persona persona) async {
    _personas.add(persona);
    await _save();
    notifyListeners();
  }

  Future<void> updatePersona(Persona persona) async {
    final idx = _personas.indexWhere((p) => p.id == persona.id);
    if (idx != -1) {
      _personas[idx] = persona;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deletePersona(String id) async {
    _personas.removeWhere((p) => p.id == id);
    if (_activePersonaId == id) {
      _activePersonaId = _personas.isNotEmpty ? _personas.first.id : 'default-assistant';
    }
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
      'claudeModel': _claudeModel,
      'temperature': _temperature,
      'webSearchEnabled': _webSearchEnabled,
      'activePersonaId': _activePersonaId,
      'personas': _personas.map((p) => p.toJson()).toList(),
    });
  }
}
