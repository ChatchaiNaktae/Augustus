import 'dart:math';
import 'package:flutter/material.dart';

enum HairStyle {
  classic,
  spiky,
  ponytail,
  bob,
  bald;

  String get displayName {
    switch (this) {
      case HairStyle.classic:
        return 'Classic';
      case HairStyle.spiky:
        return 'Spiky Anime';
      case HairStyle.ponytail:
        return 'Ponytail';
      case HairStyle.bob:
        return 'Retro Bob';
      case HairStyle.bald:
        return 'Bald / Clean';
    }
  }
}

enum HatType {
  cap,
  bandana,
  crown,
  none;

  String get displayName {
    switch (this) {
      case HatType.cap:
        return 'The Kid Cap';
      case HatType.bandana:
        return 'Hero Bandana';
      case HatType.crown:
        return 'Golden Crown';
      case HatType.none:
        return 'No Headwear';
    }
  }
}

class PlayerCustomization {
  final HairStyle hairStyle;
  final int hairColor;
  final int skinColor;
  final int shirtColor;
  final int pantsColor;
  final HatType hatType;
  final int hatColor;
  final bool capeEnabled;
  final int capeColor;
  final int shoesColor;

  const PlayerCustomization({
    required this.hairStyle,
    required this.hairColor,
    required this.skinColor,
    required this.shirtColor,
    required this.pantsColor,
    required this.hatType,
    required this.hatColor,
    required this.capeEnabled,
    required this.capeColor,
    required this.shoesColor,
  });

  /// The authentic classic "The Kid" style
  factory PlayerCustomization.defaultTheKid() {
    return const PlayerCustomization(
      hairStyle: HairStyle.classic,
      hairColor: 0xFF4C566A, // Charcoal Brown
      skinColor: 0xFFF0C09E, // Peach skin
      shirtColor: 0xFF81A1C1, // Soft blue shirt
      pantsColor: 0xFF3B4252, // Dark overalls
      hatType: HatType.cap,
      hatColor: 0xFFBF616A, // Classic Red Cap
      capeEnabled: true,
      capeColor: 0xFFE5E9F0, // Soft white cape
      shoesColor: 0xFF2E3440,
    );
  }

  factory PlayerCustomization.randomize() {
    final rand = Random();
    final hairStyles = HairStyle.values;
    final hatTypes = HatType.values;

    final skinPalette = [
      0xFFF0C09E, // Peach
      0xFFFFDFC4, // Pale
      0xFFD19D73, // Tan
      0xFF8D5524, // Dark
      0xFFA3BE8C, // Alien Green
      0xFF88C0D0, // Zombie Blue
    ];

    final vibrantPalette = [
      0xFFBF616A, // Crimson Red
      0xFFD08770, // Orange
      0xFFEBCB8B, // Gold Yellow
      0xFFA3BE8C, // Forest Green
      0xFF88C0D0, // Cyan
      0xFF81A1C1, // Sky Blue
      0xFFB48EAD, // Purple
      0xFF2E3440, // Night Black
      0xFFECEFF4, // Pure White
      0xFFFF69B4, // Hot Pink
    ];

    return PlayerCustomization(
      hairStyle: hairStyles[rand.nextInt(hairStyles.length)],
      hairColor: vibrantPalette[rand.nextInt(vibrantPalette.length)],
      skinColor: skinPalette[rand.nextInt(skinPalette.length)],
      shirtColor: vibrantPalette[rand.nextInt(vibrantPalette.length)],
      pantsColor: vibrantPalette[rand.nextInt(vibrantPalette.length)],
      hatType: hatTypes[rand.nextInt(hatTypes.length)],
      hatColor: vibrantPalette[rand.nextInt(vibrantPalette.length)],
      capeEnabled: rand.nextBool(),
      capeColor: vibrantPalette[rand.nextInt(vibrantPalette.length)],
      shoesColor: vibrantPalette[rand.nextInt(vibrantPalette.length)],
    );
  }

  PlayerCustomization copyWith({
    HairStyle? hairStyle,
    int? hairColor,
    int? skinColor,
    int? shirtColor,
    int? pantsColor,
    HatType? hatType,
    int? hatColor,
    bool? capeEnabled,
    int? capeColor,
    int? shoesColor,
  }) {
    return PlayerCustomization(
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      skinColor: skinColor ?? this.skinColor,
      shirtColor: shirtColor ?? this.shirtColor,
      pantsColor: pantsColor ?? this.pantsColor,
      hatType: hatType ?? this.hatType,
      hatColor: hatColor ?? this.hatColor,
      capeEnabled: capeEnabled ?? this.capeEnabled,
      capeColor: capeColor ?? this.capeColor,
      shoesColor: shoesColor ?? this.shoesColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hairStyle': hairStyle.name,
      'hairColor': hairColor,
      'skinColor': skinColor,
      'shirtColor': shirtColor,
      'pantsColor': pantsColor,
      'hatType': hatType.name,
      'hatColor': hatColor,
      'capeEnabled': capeEnabled,
      'capeColor': capeColor,
      'shoesColor': shoesColor,
    };
  }

  factory PlayerCustomization.fromJson(Map<String, dynamic> json) {
    HairStyle parsedHair = HairStyle.classic;
    if (json['hairStyle'] != null) {
      parsedHair = HairStyle.values.firstWhere(
        (e) => e.name == json['hairStyle'],
        orElse: () => HairStyle.classic,
      );
    }

    HatType parsedHat = HatType.cap;
    if (json['hatType'] != null) {
      parsedHat = HatType.values.firstWhere(
        (e) => e.name == json['hatType'],
        orElse: () => HatType.cap,
      );
    }

    return PlayerCustomization(
      hairStyle: parsedHair,
      hairColor: json['hairColor'] as int? ?? 0xFF4C566A,
      skinColor: json['skinColor'] as int? ?? 0xFFF0C09E,
      shirtColor: json['shirtColor'] as int? ?? 0xFF81A1C1,
      pantsColor: json['pantsColor'] as int? ?? 0xFF3B4252,
      hatType: parsedHat,
      hatColor: json['hatColor'] as int? ?? 0xFFBF616A,
      capeEnabled: json['capeEnabled'] as bool? ?? true,
      capeColor: json['capeColor'] as int? ?? 0xFFE5E9F0,
      shoesColor: json['shoesColor'] as int? ?? 0xFF2E3440,
    );
  }

  Color get hairColorValue => Color(hairColor);
  Color get skinColorValue => Color(skinColor);
  Color get shirtColorValue => Color(shirtColor);
  Color get pantsColorValue => Color(pantsColor);
  Color get hatColorValue => Color(hatColor);
  Color get capeColorValue => Color(capeColor);
  Color get shoesColorValue => Color(shoesColor);
}
