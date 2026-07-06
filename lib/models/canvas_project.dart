import 'package:flutter/material.dart';

class CanvasElement {
  String id;
  double x;
  double y;
  double width;
  double height;
  double rotation;
  int zOrder;
  String type; // 'image', 'note', 'group'
  String? imageBase64;
  String? imagePrompt;
  String? text;
  int? colorValue;
  List<String> connectedTo;

  CanvasElement({
    required this.id,
    required this.x,
    required this.y,
    this.width = 200,
    this.height = 200,
    this.rotation = 0,
    this.zOrder = 0,
    required this.type,
    this.imageBase64,
    this.imagePrompt,
    this.text,
    this.colorValue,
    List<String>? connectedTo,
  }) : connectedTo = connectedTo ?? [];

  Color get color => colorValue != null ? Color(colorValue!) : const Color(0xFF7C4DFF);

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': rotation,
    'zOrder': zOrder,
    'type': type,
    if (imageBase64 != null) 'imageBase64': imageBase64,
    if (imagePrompt != null) 'imagePrompt': imagePrompt,
    if (text != null) 'text': text,
    if (colorValue != null) 'colorValue': colorValue,
    'connectedTo': connectedTo,
  };

  factory CanvasElement.fromJson(Map<String, dynamic> json) => CanvasElement(
    id: json['id'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num?)?.toDouble() ?? 200,
    height: (json['height'] as num?)?.toDouble() ?? 200,
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    zOrder: json['zOrder'] as int? ?? 0,
    type: json['type'] as String,
    imageBase64: json['imageBase64'] as String?,
    imagePrompt: json['imagePrompt'] as String?,
    text: json['text'] as String?,
    colorValue: json['colorValue'] as int?,
    connectedTo: (json['connectedTo'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
  );
}

class CanvasProject {
  String id;
  String title;
  List<CanvasElement> elements;
  final DateTime createdAt;
  DateTime updatedAt;
  double viewportX;
  double viewportY;
  double viewportScale;

  CanvasProject({
    required this.id,
    this.title = 'Untitled Canvas',
    List<CanvasElement>? elements,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.viewportX = 0,
    this.viewportY = 0,
    this.viewportScale = 1,
  })  : elements = elements ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'elements': elements.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'viewportX': viewportX,
    'viewportY': viewportY,
    'viewportScale': viewportScale,
  };

  factory CanvasProject.fromJson(Map<String, dynamic> json) => CanvasProject(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Untitled Canvas',
    elements: (json['elements'] as List<dynamic>?)
        ?.map((e) => CanvasElement.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.now(),
    viewportX: (json['viewportX'] as num?)?.toDouble() ?? 0,
    viewportY: (json['viewportY'] as num?)?.toDouble() ?? 0,
    viewportScale: (json['viewportScale'] as num?)?.toDouble() ?? 1,
  );
}
