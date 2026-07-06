import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/canvas_project.dart';
import '../services/hive_service.dart';

const _uuid = Uuid();

class CanvasProvider extends ChangeNotifier {
  final HiveService _hiveService;

  List<CanvasProject> _projects = [];
  String? _activeProjectId;
  bool _initialized = false;

  List<CanvasProject> get projects => _projects;
  bool get initialized => _initialized;

  CanvasProject? get activeProject {
    final idx = _projects.indexWhere((p) => p.id == _activeProjectId);
    return idx != -1 ? _projects[idx] : null;
  }

  List<CanvasElement> get elements => activeProject?.elements ?? [];

  CanvasProvider(this._hiveService);

  Future<void> load() async {
    _projects = _hiveService.loadCanvasProjects();
    if (_projects.isNotEmpty) {
      _activeProjectId = _projects.first.id;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> createProject({String? title}) async {
    final project = CanvasProject(
      id: _uuid.v4(),
      title: title ?? 'Canvas ${_projects.length + 1}',
    );
    _projects.insert(0, project);
    _activeProjectId = project.id;
    await _save();
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    if (_activeProjectId == id) {
      _activeProjectId = _projects.isNotEmpty ? _projects.first.id : null;
    }
    await _save();
    notifyListeners();
  }

  void selectProject(String id) {
    _activeProjectId = id;
    notifyListeners();
  }

  void addElement(CanvasElement element) {
    final project = activeProject;
    if (project == null) return;
    project.elements.add(element);
    project.updatedAt = DateTime.now();
    _save();
    notifyListeners();
  }

  void updateElement(String elementId, CanvasElement updated) {
    final project = activeProject;
    if (project == null) return;
    final idx = project.elements.indexWhere((e) => e.id == elementId);
    if (idx == -1) return;
    project.elements[idx] = updated;
    project.updatedAt = DateTime.now();
    _save();
    notifyListeners();
  }

  void removeElement(String elementId) {
    final project = activeProject;
    if (project == null) return;
    project.elements.removeWhere((e) => e.id == elementId);
    for (final e in project.elements) {
      e.connectedTo.remove(elementId);
    }
    project.updatedAt = DateTime.now();
    _save();
    notifyListeners();
  }

  void moveElement(String elementId, double dx, double dy) {
    final project = activeProject;
    if (project == null) return;
    final el = project.elements.where((e) => e.id == elementId).firstOrNull;
    if (el == null) return;
    el.x += dx;
    el.y += dy;
    project.updatedAt = DateTime.now();
    notifyListeners();
  }

  void connectElements(String fromId, String toId) {
    final project = activeProject;
    if (project == null) return;
    final from = project.elements.where((e) => e.id == fromId).firstOrNull;
    if (from == null) return;
    if (!from.connectedTo.contains(toId)) {
      from.connectedTo.add(toId);
      project.updatedAt = DateTime.now();
      _save();
      notifyListeners();
    }
  }

  void disconnectElements(String fromId, String toId) {
    final project = activeProject;
    if (project == null) return;
    final from = project.elements.where((e) => e.id == fromId).firstOrNull;
    if (from == null) return;
    from.connectedTo.remove(toId);
    project.updatedAt = DateTime.now();
    _save();
    notifyListeners();
  }

  void bringToFront(String elementId) {
    final project = activeProject;
    if (project == null) return;
    final idx = project.elements.indexWhere((e) => e.id == elementId);
    if (idx == -1) return;
    final el = project.elements.removeAt(idx);
    final maxZ = project.elements.isEmpty
        ? 0
        : project.elements.map((e) => e.zOrder).reduce((a, b) => a > b ? a : b);
    el.zOrder = maxZ + 1;
    project.elements.add(el);
    project.updatedAt = DateTime.now();
    _save();
    notifyListeners();
  }

  Future<void> updateViewport(double x, double y, double scale) async {
    final project = activeProject;
    if (project == null) return;
    project.viewportX = x;
    project.viewportY = y;
    project.viewportScale = scale;
    await _save();
  }

  Future<void> renameProject(String id, String title) async {
    final idx = _projects.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _projects[idx].title = title;
      await _save();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    await _hiveService.saveCanvasProjects(_projects);
  }
}
