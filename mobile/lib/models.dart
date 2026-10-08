import 'package:flutter/material.dart';

/// Sama dengan Todo::DESCRIPTION_MAX di backend.
const descriptionMax = 10000;

const uncategorizedLabel = 'Tanpa Kategori';

Color parseHexColor(String? hex, [Color fallback = const Color(0xFF9CA3AF)]) {
  if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return fallback;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

class User {
  final int id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> j) =>
      User(id: j['id'] as int, name: j['name'] as String, email: j['email'] as String);
}

class Category {
  final int id;
  final String name;
  final String color;
  final int? todosCount;
  final int? pendingCount;

  const Category({required this.id, required this.name, required this.color, this.todosCount, this.pendingCount});

  Color get colorValue => parseHexColor(color);

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        name: j['name'] as String,
        color: j['color'] as String,
        todosCount: j['todos_count'] as int?,
        pendingCount: j['pending_count'] as int?,
      );
}

/// Kategori yang tertanam di todo; id null = "Tanpa Kategori".
class TodoCategory {
  final int? id;
  final String name;
  final String color;

  const TodoCategory({required this.id, required this.name, required this.color});

  Color get colorValue => parseHexColor(color);

  factory TodoCategory.fromJson(Map<String, dynamic> j) =>
      TodoCategory(id: j['id'] as int?, name: j['name'] as String, color: j['color'] as String);
}

class Todo {
  final int id;
  final String title;
  final String? description;
  final String dueDate; // YYYY-MM-DD
  final bool isCompleted;
  final int? categoryId;
  final TodoCategory category;

  const Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
    required this.categoryId,
    required this.category,
  });

  factory Todo.fromJson(Map<String, dynamic> j) => Todo(
        id: j['id'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        dueDate: j['due_date'] as String,
        isCompleted: j['is_completed'] == true,
        categoryId: j['category_id'] as int?,
        category: TodoCategory.fromJson(j['category'] as Map<String, dynamic>),
      );

  Todo copyWith({bool? isCompleted}) => Todo(
        id: id,
        title: title,
        description: description,
        dueDate: dueDate,
        isCompleted: isCompleted ?? this.isCompleted,
        categoryId: categoryId,
        category: category,
      );
}

class TodoInput {
  final String title;
  final String? description;
  final String dueDate;
  final int? categoryId;

  const TodoInput({required this.title, this.description, required this.dueDate, this.categoryId});

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'due_date': dueDate,
        'category_id': categoryId,
      };
}

class TodoFilters {
  final String? search;
  final String? categoryId; // id atau "none"
  final String? date;
  final int? month;
  final int? year;
  final String? status; // pending | completed

  const TodoFilters({this.search, this.categoryId, this.date, this.month, this.year, this.status});

  Map<String, String> toQuery() => {
        if (search != null && search!.isNotEmpty) 'search': search!,
        if (categoryId != null && categoryId!.isNotEmpty) 'category_id': categoryId!,
        'date': ?date,
        if (month != null) 'month': '$month',
        if (year != null) 'year': '$year',
        'status': ?status,
      };
}
