// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

enum HairStyle {
  none,
  short,
  long,
  spiky,
  curly,
  bob,
  mohawk,
  baldWithSides,
}

enum Accessory {
  none,
  glasses,
  hat,
  headphones,
}

class AvatarConfig {
  const AvatarConfig({
    this.bodyColor = const Color(0xFFFCEBD6),
    this.skinTone = const Color(0xFFFCEBD6),
    this.hairStyle = HairStyle.none,
    this.hairColor = const Color(0xFF4A2912),
    this.outfitColor = const Color(0xFFA43B2F),
    this.accessory = Accessory.none,
  });

  final Color bodyColor;
  final Color skinTone;
  final HairStyle hairStyle;
  final Color hairColor;
  final Color outfitColor;
  final Accessory accessory;

  factory AvatarConfig.fromMap(Map<String, dynamic> map) {
    return AvatarConfig(
      bodyColor: Color(map['bodyColor'] ?? 0xFFFCEBD6),
      skinTone: Color(map['skinTone'] ?? 0xFFFCEBD6),
      hairStyle: HairStyle.values[map['hairStyle'] ?? 0],
      hairColor: Color(map['hairColor'] ?? 0xFF4A2912),
      outfitColor: Color(map['outfitColor'] ?? 0xFFA43B2F),
      accessory: Accessory.values[map['accessory'] ?? 0],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bodyColor': bodyColor.value,
      'skinTone': skinTone.value,
      'hairStyle': hairStyle.index,
      'hairColor': hairColor.value,
      'outfitColor': outfitColor.value,
      'accessory': accessory.index,
    };
  }

  AvatarConfig copyWith({
    Color? bodyColor,
    Color? skinTone,
    HairStyle? hairStyle,
    Color? hairColor,
    Color? outfitColor,
    Accessory? accessory,
  }) {
    return AvatarConfig(
      bodyColor: bodyColor ?? this.bodyColor,
      skinTone: skinTone ?? this.skinTone,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      outfitColor: outfitColor ?? this.outfitColor,
      accessory: accessory ?? this.accessory,
    );
  }

  static const skinTones = [
    Color(0xFFFDDBB4),
    Color(0xFFE8AA76),
    Color(0xFFC68642),
    Color(0xFF8D5524),
    Color(0xFF4A2912),
    Color(0xFFFCEBD6),
  ];

  static const outfitColors = [
    Color(0xFFA43B2F), // Coral Primary
    Color(0xFFFF7F6E), // Coral Container
    Color(0xFF1A1C1A), // Black
    Color(0xFF333333), // Dark Grey
    Color(0xFFD4A373), // Warm Earth
    Color(0xFF95A5A6), // Gray
  ];
}
