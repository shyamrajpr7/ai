import 'package:flutter/material.dart';

class Persona {
  final String id;
  String name;
  String systemPrompt;
  String emoji;
  Color color;

  Persona({
    required this.id,
    required this.name,
    required this.systemPrompt,
    this.emoji = '🤖',
    this.color = const Color(0xFF7C4DFF),
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'systemPrompt': systemPrompt,
    'emoji': emoji,
    'color': color.value,
  };

  factory Persona.fromJson(Map<String, dynamic> json) => Persona(
    id: json['id'] as String,
    name: json['name'] as String,
    systemPrompt: json['systemPrompt'] as String,
    emoji: json['emoji'] as String? ?? '🤖',
    color: Color(json['color'] as int? ?? 0xFF7C4DFF),
  );

  Persona copyWith({
    String? id,
    String? name,
    String? systemPrompt,
    String? emoji,
    Color? color,
  }) {
    return Persona(
      id: id ?? this.id,
      name: name ?? this.name,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
    );
  }

  static List<Persona> defaults = [
    Persona(
      id: 'default-assistant',
      name: 'Nexus',
      systemPrompt:
          'You are the Nexus AI assistant. You provide helpful, concise, and accurate responses.',
      emoji: '🤖',
    ),
    Persona(
      id: 'default-coder',
      name: 'Code Expert',
      systemPrompt:
          'You are an expert software engineer. Provide clean, idiomatic code with best practices. Explain your reasoning concisely.',
      emoji: '💻',
      color: Color(0xFF448AFF),
    ),
    Persona(
      id: 'default-writer',
      name: 'Creative Writer',
      systemPrompt:
          'You are a creative writing assistant. Help craft engaging stories, poems, and creative content with vivid language.',
      emoji: '✍️',
      color: Color(0xFFFF4081),
    ),
    Persona(
      id: 'default-tutor',
      name: 'Tutor',
      systemPrompt:
          'You are a patient and knowledgeable tutor. Explain concepts step by step, use analogies, and ask questions to reinforce learning.',
      emoji: '📚',
      color: Color(0xFF00E676),
    ),
  ];
}
