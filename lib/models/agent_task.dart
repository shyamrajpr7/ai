import 'package:flutter/material.dart';

enum AgentStepStatus { pending, running, completed, failed }

class AgentStep {
  final String id;
  String title;
  String description;
  AgentStepStatus status;
  String? result;
  String? error;
  DateTime? startedAt;
  DateTime? completedAt;
  int tokensUsed;
  List<AgentLogEntry> logs;

  AgentStep({
    required this.id,
    required this.title,
    this.description = '',
    this.status = AgentStepStatus.pending,
    this.result,
    this.error,
    this.startedAt,
    this.completedAt,
    this.tokensUsed = 0,
    List<AgentLogEntry>? logs,
  }) : logs = logs ?? [];

  Duration? get duration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status.index,
    'result': result,
    'error': error,
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'tokensUsed': tokensUsed,
    'logs': logs.map((l) => l.toJson()).toList(),
  };

  factory AgentStep.fromJson(Map<String, dynamic> json) => AgentStep(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    status: AgentStepStatus.values[json['status'] as int? ?? 0],
    result: json['result'] as String?,
    error: json['error'] as String?,
    startedAt: json['startedAt'] != null
        ? DateTime.parse(json['startedAt'] as String)
        : null,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    tokensUsed: json['tokensUsed'] as int? ?? 0,
    logs: (json['logs'] as List<dynamic>?)
        ?.map((l) => AgentLogEntry.fromJson(l as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class AgentLogEntry {
  final String message;
  final String level; // 'info', 'tool', 'thought', 'error', 'result'
  final DateTime timestamp;

  AgentLogEntry({
    required this.message,
    this.level = 'info',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'message': message,
    'level': level,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AgentLogEntry.fromJson(Map<String, dynamic> json) => AgentLogEntry(
    message: json['message'] as String,
    level: json['level'] as String? ?? 'info',
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : DateTime.now(),
  );

  Color get displayColor {
    switch (level) {
      case 'tool': return const Color(0xFF448AFF);
      case 'thought': return const Color(0xFF7C4DFF);
      case 'error': return const Color(0xFFFF5252);
      case 'result': return const Color(0xFF00E676);
      default: return Colors.white.withOpacity(0.6);
    }
  }

  IconData get icon {
    switch (level) {
      case 'tool': return Icons.build_outlined;
      case 'thought': return Icons.psychology_outlined;
      case 'error': return Icons.error_outline;
      case 'result': return Icons.check_circle_outline;
      default: return Icons.info_outline;
    }
  }
}

class AgentTask {
  final String id;
  String title;
  final String objective;
  List<AgentStep> steps;
  AgentStepStatus status;
  DateTime createdAt;
  DateTime? completedAt;
  String? finalResult;
  int totalTokens;
  String? error;

  AgentTask({
    required this.id,
    required this.objective,
    this.title = 'Agent Task',
    List<AgentStep>? steps,
    this.status = AgentStepStatus.pending,
    DateTime? createdAt,
    this.completedAt,
    this.finalResult,
    this.totalTokens = 0,
    this.error,
  })  : steps = steps ?? [],
        createdAt = createdAt ?? DateTime.now();

  Duration? get totalDuration {
    if (completedAt == null) return null;
    return completedAt!.difference(createdAt);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'objective': objective,
    'steps': steps.map((s) => s.toJson()).toList(),
    'status': status.index,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'finalResult': finalResult,
    'totalTokens': totalTokens,
    'error': error,
  };

  factory AgentTask.fromJson(Map<String, dynamic> json) => AgentTask(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Agent Task',
    objective: json['objective'] as String? ?? '',
    steps: (json['steps'] as List<dynamic>?)
        ?.map((s) => AgentStep.fromJson(s as Map<String, dynamic>))
        .toList() ?? [],
    status: AgentStepStatus.values[json['status'] as int? ?? 0],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    finalResult: json['finalResult'] as String?,
    totalTokens: json['totalTokens'] as int? ?? 0,
    error: json['error'] as String?,
  );
}
