import 'package:flutter/material.dart';

class TaskCategory {
  final int? id;
  final String name;
  final int colorValue;
  final String? iconName;

  const TaskCategory({
    this.id,
    required this.name,
    required this.colorValue,
    this.iconName,
  });

  Color get color => Color(colorValue);

  TaskCategory copyWith({
    int? id,
    String? name,
    int? colorValue,
    String? iconName,
  }) {
    return TaskCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
    );
  }
}
