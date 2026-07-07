import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/knowledge_graph.dart';
import '../models/chat_message.dart';
import '../services/hive_service.dart';

const _uuid = Uuid();

class KnowledgeGraphProvider extends ChangeNotifier {
  final HiveService _hiveService;
  List<KnowledgeNode> _nodes = [];
  List<KnowledgeEdge> _edges = [];
  bool _initialized = false;
  bool _isExtracting = false;

  List<KnowledgeNode> get nodes => List.unmodifiable(_nodes);
  List<KnowledgeEdge> get edges => List.unmodifiable(_edges);
  bool get initialized => _initialized;
  bool get isExtracting => _isExtracting;

  static const _stopWords = {
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'by', 'with', 'from', 'as', 'is', 'was', 'are', 'were', 'be',
    'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did',
    'would', 'could', 'should', 'may', 'might', 'shall', 'need',
    'this', 'that', 'these', 'those', 'it', 'its', 'you', 'your', 'we',
    'our', 'they', 'their', 'he', 'she', 'him', 'her', 'his', 'not',
    'just', 'like', 'about', 'what', 'which', 'who', 'how', 'when',
    'where', 'why', 'all', 'each', 'every', 'some', 'any', 'no', 'none',
    'more', 'most', 'other', 'such', 'only', 'own', 'same', 'so', 'than',
    'too', 'very', 'get', 'got', 'make', 'made', 'use',
    'used', 'using', 'know', 'think', 'want', 'see', 'look',
    'say', 'tell', 'ask', 'help', 'work', 'try', 'let', 'good',
    'new', 'first', 'last', 'great', 'much', 'also', 'well', 'back',
    'even', 'still', 'already', 'please', 'thanks', 'thank', 'yes',
    'ok', 'okay', 'sure', 'right', 'way', 'thing', 'things', 'going',
    'really', 'actually', 'pretty', 'quite', 'maybe', 'perhaps', 'probably',
    'ever', 'never', 'always', 'often', 'usually', 'here', 'there',
  };

  static const _techTerms = {
    'api', 'json', 'html', 'css', 'http', 'rest', 'sql', 'git',
    'npm', 'yarn', 'node', 'react', 'vue', 'angular', 'flutter',
    'dart', 'python', 'java', 'rust', 'go', 'typescript', 'javascript',
    'docker', 'kubernetes', 'aws', 'azure', 'gcp', 'linux', 'macos',
    'windows', 'android', 'ios', 'ai', 'ml', 'llm', 'gpt', 'claude',
    'groq', 'ollama', 'hive', 'provider', 'bloc', 'redux', 'graphql',
  };

  KnowledgeGraphProvider(this._hiveService);

  Future<void> load() async {
    final data = _hiveService.loadKnowledgeGraph();
    if (data != null) {
      final nodesRaw = data['nodes'] as List<dynamic>? ?? [];
      final edgesRaw = data['edges'] as List<dynamic>? ?? [];
      _nodes = nodesRaw
          .map((e) => KnowledgeNode.fromJson(e as Map<String, dynamic>))
          .toList();
      _edges = edgesRaw
          .map((e) => KnowledgeEdge.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> extractFromMessages(List<ChatMessage> messages) async {
    _isExtracting = true;
    notifyListeners();

    for (final msg in messages) {
      if (msg.role != 'assistant') continue;
      _extractEntities(msg.content, msg.id);
    }

    _runLayout();
    await _save();
    _isExtracting = false;
    notifyListeners();
  }

  void _extractEntities(String content, String messageId) {
    final entities = <String>{};
    final lower = content.toLowerCase();

    for (final term in _techTerms) {
      if (lower.contains(term)) {
        entities.add(term);
      }
    }

    final hashtagRegExp = RegExp(r'#(\w+)');
    for (final match in hashtagRegExp.allMatches(content)) {
      entities.add(match.group(1)!);
    }

    final words = content.split(RegExp('[\\s,.;:!?()\\[\\]{}"\']+'));
    for (int i = 0; i < words.length - 1; i++) {
      if (words[i].isEmpty) continue;
      final firstChar = words[i].codeUnitAt(0);
      if (firstChar >= 65 && firstChar <= 90) {
        final phrase = [words[i]];
        for (int j = i + 1; j < words.length; j++) {
          if (words[j].isEmpty) break;
          final c = words[j].codeUnitAt(0);
          if (c >= 65 && c <= 90) {
            phrase.add(words[j]);
          } else {
            break;
          }
        }
        if (phrase.length >= 2) {
          entities.add(phrase.join(' '));
        }
      }
    }

    final freq = <String, int>{};
    for (final word in words) {
      final w = word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      if (w.length < 4) continue;
      if (_stopWords.contains(w)) continue;
      if (RegExp(r'^\d+$').hasMatch(w)) continue;
      freq[w] = (freq[w] ?? 0) + 1;
    }

    final threshold = 3;
    for (final entry in freq.entries) {
      if (entry.value >= threshold) {
        entities.add(entry.key);
      }
    }

    final entityList = entities.toList();
    for (int i = 0; i < entityList.length; i++) {
      _addOrUpdateNode(entityList[i], messageId);
      for (int j = i + 1; j < entityList.length; j++) {
        _addOrUpdateEdge(entityList[i], entityList[j]);
      }
    }
  }

  void _addOrUpdateNode(String label, String messageId) {
    final labelLower = label.toLowerCase();
    final existing = _nodes.where(
      (n) => n.label.toLowerCase() == labelLower,
    ).firstOrNull;

    if (existing != null) {
      final updatedMessages = existing.messageIds.contains(messageId)
          ? existing.messageIds
          : [...existing.messageIds, messageId];
      existing.frequency += 1;
      existing.importance = _computeImportance(existing.frequency);
      existing.messageIds = updatedMessages;
    } else {
      final type = _inferType(label);
      final colorValue = _typeColor(type);
      _nodes.add(KnowledgeNode(
        id: _uuid.v4(),
        label: label,
        type: type,
        messageIds: [messageId],
        colorValue: colorValue,
      ));
    }
  }

  void _addOrUpdateEdge(String sourceLabel, String targetLabel) {
    final source = _nodes.where(
      (n) => n.label.toLowerCase() == sourceLabel.toLowerCase(),
    ).firstOrNull;
    final target = _nodes.where(
      (n) => n.label.toLowerCase() == targetLabel.toLowerCase(),
    ).firstOrNull;
    if (source == null || target == null || source.id == target.id) return;

    final existing = _edges.where((e) =>
      (e.sourceId == source.id && e.targetId == target.id) ||
      (e.sourceId == target.id && e.targetId == source.id)
    ).firstOrNull;

    if (existing != null) {
      existing.weight += 1;
    } else {
      _edges.add(KnowledgeEdge(
        id: _uuid.v4(),
        sourceId: source.id,
        targetId: target.id,
        weight: 1.0,
      ));
    }
  }

  double _computeImportance(int frequency) {
    return (frequency / (frequency + 5)).clamp(0.1, 1.0);
  }

  String _inferType(String label) {
    final lower = label.toLowerCase();
    if (label.startsWith('#')) return 'hashtag';
    if (_techTerms.contains(lower)) return 'technology';
    if (label.length >= 3 && label[0] == label[0].toUpperCase() &&
        RegExp(r'^[A-Z][a-z]+').hasMatch(label)) {
      return 'concept';
    }
    return 'topic';
  }

  int _typeColor(String type) {
    switch (type) {
      case 'technology': return 0xFF448AFF;
      case 'hashtag': return 0xFFE040FB;
      case 'concept': return 0xFF00E676;
      case 'person': return 0xFFFFAB00;
      case 'place': return 0xFF00BCD4;
      default: return 0xFF7C4DFF;
    }
  }

  void _runLayout() {
    if (_nodes.isEmpty) return;
    final rng = Random(42);
    final center = const Offset(400, 400);
    final radius = 300.0;

    for (int i = 0; i < _nodes.length; i++) {
      final angle = (2 * pi / _nodes.length) * i + rng.nextDouble() * 0.3;
      final r = radius * (0.4 + rng.nextDouble() * 0.6);
      _nodes[i].x = center.dx + r * cos(angle);
      _nodes[i].y = center.dy + r * sin(angle);
    }

    for (int iter = 0; iter < 50; iter++) {
      _applyForceDirected(rng);
    }

    _normalizePositions();
  }

  void _applyForceDirected(Random rng) {
    const repulsion = 5000;
    const attraction = 0.01;
    const damping = 0.85;

    final forces = <String, Offset>{};
    for (final node in _nodes) {
      forces[node.id] = Offset.zero;
    }

    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final a = _nodes[i];
        final b = _nodes[j];
        var dx = a.x - b.x;
        var dy = a.y - b.y;
        var dist = sqrt(dx * dx + dy * dy);
        if (dist < 1) dist = 1;
        final force = repulsion / (dist * dist);
        final fx = dx / dist * force;
        final fy = dy / dist * force;
        forces[a.id] = forces[a.id]! + Offset(fx, fy);
        forces[b.id] = forces[b.id]! - Offset(fx, fy);
      }
    }

    for (final edge in _edges) {
      final source = _nodes.where((n) => n.id == edge.sourceId).firstOrNull;
      final target = _nodes.where((n) => n.id == edge.targetId).firstOrNull;
      if (source == null || target == null) continue;
      var dx = target.x - source.x;
      var dy = target.y - source.y;
      var dist = sqrt(dx * dx + dy * dy);
      if (dist < 1) dist = 1;
      final force = attraction * edge.weight * dist;
      final fx = dx / dist * force;
      final fy = dy / dist * force;
      forces[source.id] = forces[source.id]! + Offset(fx, fy);
      forces[target.id] = forces[target.id]! - Offset(fx, fy);
    }

    for (final node in _nodes) {
      node.x += forces[node.id]!.dx * damping;
      node.y += forces[node.id]!.dy * damping;
    }
  }

  void _normalizePositions() {
    if (_nodes.isEmpty) return;
    var minX = _nodes.first.x;
    var maxX = _nodes.first.x;
    var minY = _nodes.first.y;
    var maxY = _nodes.first.y;

    for (final node in _nodes) {
      if (node.x < minX) minX = node.x;
      if (node.x > maxX) maxX = node.x;
      if (node.y < minY) minY = node.y;
      if (node.y > maxY) maxY = node.y;
    }

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    if (rangeX < 1 && rangeY < 1) return;

    const targetSize = 600.0;
    final scale = targetSize / (rangeX > rangeY ? rangeX : rangeY);
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;

    for (final node in _nodes) {
      node.x = (node.x - cx) * scale + 400;
      node.y = (node.y - cy) * scale + 400;
    }
  }

  List<KnowledgeNode> getConnectedNodes(String nodeId) {
    final connectedIds = <String>{};
    for (final edge in _edges) {
      if (edge.sourceId == nodeId) connectedIds.add(edge.targetId);
      if (edge.targetId == nodeId) connectedIds.add(edge.sourceId);
    }
    return _nodes.where((n) => connectedIds.contains(n.id)).toList();
  }

  List<KnowledgeEdge> getNodeEdges(String nodeId) {
    return _edges.where((e) =>
      e.sourceId == nodeId || e.targetId == nodeId
    ).toList();
  }

  void removeNode(String id) {
    _nodes.removeWhere((n) => n.id == id);
    _edges.removeWhere((e) => e.sourceId == id || e.targetId == id);
    _save();
    notifyListeners();
  }

  void clearAll() {
    _nodes.clear();
    _edges.clear();
    _hiveService.saveKnowledgeGraph({'nodes': [], 'edges': []});
    notifyListeners();
  }

  Future<void> _save() async {
    await _hiveService.saveKnowledgeGraph({
      'nodes': _nodes.map((n) => n.toJson()).toList(),
      'edges': _edges.map((e) => e.toJson()).toList(),
    });
  }
}
