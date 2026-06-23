import 'package:flutter/material.dart';

/// Model representing a routine (shared or solo) and its current daily status.
class RoutineModel {
  const RoutineModel({
    required this.id,
    this.duoId,
    this.userId,
    required this.title,
    required this.description,
    required this.time,
    required this.iconCode,
    this.category = 'mindfulness',
    this.isCompleted = false,
    this.partnerCompleted = false,
    this.createdAt,
  });

  final String id;
  final String? duoId;
  final String? userId;
  final String title;
  final String description;
  final String time;
  final int iconCode;
  final String category;
  
  // These are transient fields populated by the service/join
  final bool isCompleted;
  final bool partnerCompleted;
  final DateTime? createdAt;

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  factory RoutineModel.fromMap(Map<String, dynamic> map, {
    bool isCompleted = false,
    bool partnerCompleted = false,
  }) {
    return RoutineModel(
      id: map['id'] as String? ?? '',
      duoId: map['duoId'] as String? ?? map['duo_id'] as String?,
      userId: map['userId'] as String? ?? map['user_id'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      time: map['time'] as String? ?? '',
      iconCode: (map['iconCode'] ?? map['icon_code'] ?? 58713) as int,
      category: map['category'] as String? ?? 'mindfulness',
      isCompleted: isCompleted,
      partnerCompleted: partnerCompleted,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'duo_id': duoId,
      'user_id': userId,
      'title': title,
      'description': description,
      'time': time,
      'icon_code': iconCode,
      // 'category': category, // Uncomment this once you add the 'category' column to your Supabase 'routines' table
    };
  }

  RoutineModel copyWith({
    bool? isCompleted,
    bool? partnerCompleted,
    String? category,
  }) {
    return RoutineModel(
      id: id,
      duoId: duoId,
      userId: userId,
      title: title,
      description: description,
      time: time,
      iconCode: iconCode,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      partnerCompleted: partnerCompleted ?? this.partnerCompleted,
      createdAt: createdAt,
    );
  }
}
