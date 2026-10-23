import 'dart:convert';
import 'package:flutter/material.dart';

enum StageElementType {
  platform,
  movingPlatform,
  rotatingPlatform,
  collapsingBlock,
  spike,
  slidingSpike,
  apple,
  turret,
  sniper,
  triggerZone,
  savePoint,
  goal;

  String get displayName {
    switch (this) {
      case StageElementType.platform:
        return 'Solid Platform';
      case StageElementType.movingPlatform:
        return 'Moving Platform';
      case StageElementType.rotatingPlatform:
        return 'Rotating Platform';
      case StageElementType.collapsingBlock:
        return 'Collapsing Block';
      case StageElementType.spike:
        return 'Spike Hazard';
      case StageElementType.slidingSpike:
        return 'Sliding Spike';
      case StageElementType.apple:
        return 'Apple Hazard';
      case StageElementType.turret:
        return 'Turret Gun';
      case StageElementType.sniper:
        return 'Sniper Laser';
      case StageElementType.triggerZone:
        return 'Trigger Zone';
      case StageElementType.savePoint:
        return 'Save Point (Checkpoint)';
      case StageElementType.goal:
        return 'Goal Portal';
    }
  }

  IconData get icon {
    switch (this) {
      case StageElementType.platform:
        return Icons.view_headline;
      case StageElementType.movingPlatform:
        return Icons.swap_horiz;
      case StageElementType.rotatingPlatform:
        return Icons.rotate_right;
      case StageElementType.collapsingBlock:
        return Icons.vertical_align_bottom;
      case StageElementType.spike:
        return Icons.warning_amber_rounded;
      case StageElementType.slidingSpike:
        return Icons.arrow_forward;
      case StageElementType.apple:
        return Icons.circle;
      case StageElementType.turret:
        return Icons.adjust;
      case StageElementType.sniper:
        return Icons.gps_fixed;
      case StageElementType.triggerZone:
        return Icons.crop_square;
      case StageElementType.savePoint:
        return Icons.save;
      case StageElementType.goal:
        return Icons.flag;
    }
  }

  Color get categoryColor {
    switch (this) {
      case StageElementType.platform:
      case StageElementType.movingPlatform:
      case StageElementType.rotatingPlatform:
      case StageElementType.collapsingBlock:
        return const Color(0xFF81A1C1); // Blue
      case StageElementType.spike:
      case StageElementType.slidingSpike:
        return const Color(0xFFBF616A); // Red
      case StageElementType.apple:
        return const Color(0xFFD08770); // Orange
      case StageElementType.turret:
      case StageElementType.sniper:
        return const Color(0xFFB48EAD); // Purple
      case StageElementType.triggerZone:
        return const Color(0xFF88C0D0); // Cyan
      case StageElementType.savePoint:
        return const Color(0xFFA3BE8C); // Green
      case StageElementType.goal:
        return const Color(0xFFEBCB8B); // Yellow
    }
  }
}

class StageElementData {
  String id;
  StageElementType type;
  String name;
  double x;
  double y;
  double width;
  double height;
  double rotation; // in degrees (0, 90, 180, 270, etc.)
  int? color;
  Map<String, dynamic> properties;

  StageElementData({
    required this.id,
    required this.type,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    this.color,
    Map<String, dynamic>? properties,
  }) : properties = properties ?? {};

  StageElementData copyWith({
    String? id,
    StageElementType? type,
    String? name,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? color,
    Map<String, dynamic>? properties,
  }) {
    return StageElementData(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      properties: properties != null ? Map.from(properties) : Map.from(this.properties),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'color': color,
      'properties': properties,
    };
  }

  factory StageElementData.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'platform';
    final type = StageElementType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => StageElementType.platform,
    );

    return StageElementData(
      id: json['id'] as String? ?? UniqueKey().toString(),
      type: type,
      name: json['name'] as String? ?? type.displayName,
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 32.0,
      height: (json['height'] as num?)?.toDouble() ?? 32.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as int?,
      properties: json['properties'] != null
          ? Map<String, dynamic>.from(json['properties'] as Map)
          : {},
    );
  }
}

class CustomStageData {
  String id;
  String title;
  String author;
  double spawnX;
  double spawnY;
  int backgroundColor;
  List<StageElementData> elements;
  DateTime createdAt;
  DateTime updatedAt;

  CustomStageData({
    required this.id,
    required this.title,
    this.author = 'Anonymous Guy',
    this.spawnX = 64.0,
    this.spawnY = 480.0,
    this.backgroundColor = 0xFF242933,
    List<StageElementData>? elements,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : elements = elements ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'spawnX': spawnX,
      'spawnY': spawnY,
      'backgroundColor': backgroundColor,
      'elements': elements.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CustomStageData.fromJson(Map<String, dynamic> json) {
    return CustomStageData(
      id: json['id'] as String? ?? UniqueKey().toString(),
      title: json['title'] as String? ?? 'Untitled Stage',
      author: json['author'] as String? ?? 'Anonymous',
      spawnX: (json['spawnX'] as num?)?.toDouble() ?? 64.0,
      spawnY: (json['spawnY'] as num?)?.toDouble() ?? 480.0,
      backgroundColor: json['backgroundColor'] as int? ?? 0xFF242933,
      elements: (json['elements'] as List<dynamic>?)
              ?.map((e) => StageElementData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Encodes stage to a shareable Base64 string with 'AGY:' header
  String exportCode() {
    final jsonStr = jsonEncode(toJson());
    final bytes = utf8.encode(jsonStr);
    final b64 = base64.encode(bytes);
    return 'AGY:$b64';
  }

  /// Imports stage from shareable Base64 string or raw JSON
  static CustomStageData? importCode(String code) {
    try {
      String cleanCode = code.trim();
      if (cleanCode.startsWith('AGY:')) {
        cleanCode = cleanCode.substring(4);
      }
      final bytes = base64.decode(cleanCode);
      final jsonStr = utf8.decode(bytes);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return CustomStageData.fromJson(map);
    } catch (_) {
      try {
        final map = jsonDecode(code) as Map<String, dynamic>;
        return CustomStageData.fromJson(map);
      } catch (_) {
        return null;
      }
    }
  }

  /// Default Starter Template: Blank room with ground and goal
  factory CustomStageData.blankTemplate({String title = 'My Custom Stage'}) {
    final stage = CustomStageData(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      spawnX: 64.0,
      spawnY: 480.0,
    );

    // Ground floor
    stage.elements.add(StageElementData(
      id: 'ground_1',
      type: StageElementType.platform,
      name: 'Ground Platform',
      x: 0,
      y: 540,
      width: 800,
      height: 60,
      color: 0xFF434C5E,
    ));

    // Goal at the right
    stage.elements.add(StageElementData(
      id: 'goal_1',
      type: StageElementType.goal,
      name: 'Victory Portal',
      x: 720,
      y: 476,
      width: 48,
      height: 64,
      color: 0xFFEBCB8B,
    ));

    return stage;
  }

  /// Parkour & Spikes Challenge Template
  factory CustomStageData.parkourTemplate() {
    final stage = CustomStageData(
      id: 'template_parkour',
      title: 'Precision Leap Challenge',
      spawnX: 48,
      spawnY: 480,
    );

    // Left ground
    stage.elements.add(StageElementData(
      id: 'ground_left',
      type: StageElementType.platform,
      name: 'Start Platform',
      x: 0,
      y: 540,
      width: 160,
      height: 60,
    ));

    // Bottom pit with spikes
    stage.elements.add(StageElementData(
      id: 'bottom_spike_1',
      type: StageElementType.spike,
      name: 'Spike Pit',
      x: 180,
      y: 568,
      width: 440,
      height: 32,
      rotation: 0,
    ));

    // Floating stepping platforms
    stage.elements.add(StageElementData(
      id: 'plat_mid_1',
      type: StageElementType.platform,
      name: 'Mid Jump 1',
      x: 240,
      y: 440,
      width: 64,
      height: 16,
    ));

    stage.elements.add(StageElementData(
      id: 'save_point_1',
      type: StageElementType.savePoint,
      name: 'Mid Checkpoint',
      x: 390,
      y: 320,
      width: 32,
      height: 32,
    ));

    stage.elements.add(StageElementData(
      id: 'plat_mid_2',
      type: StageElementType.platform,
      name: 'Mid Jump 2',
      x: 370,
      y: 352,
      width: 72,
      height: 16,
    ));

    stage.elements.add(StageElementData(
      id: 'plat_mid_3',
      type: StageElementType.movingPlatform,
      name: 'Moving Platform',
      x: 500,
      y: 280,
      width: 80,
      height: 16,
      properties: {'moveRange': 100.0, 'speed': 80.0, 'horizontal': true},
    ));

    // Right goal platform
    stage.elements.add(StageElementData(
      id: 'ground_right',
      type: StageElementType.platform,
      name: 'Goal Island',
      x: 640,
      y: 240,
      width: 160,
      height: 360,
    ));

    stage.elements.add(StageElementData(
      id: 'goal_portal',
      type: StageElementType.goal,
      name: 'Clear Portal',
      x: 720,
      y: 176,
      width: 48,
      height: 64,
    ));

    return stage;
  }
}
