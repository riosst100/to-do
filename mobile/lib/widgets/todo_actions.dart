import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import 'todo_form_sheet.dart';

void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Terjadi kesalahan.')));
}

/// Toggle, ubah & hapus todo dengan update optimistis pada list lokal.
mixin TodoListActions<T extends StatefulWidget> on State<T> {
  List<Todo> todos = [];
  List<Category> categories = [];

  Future<void> reload();

  void _replace(Todo updated) => setState(() => todos = [for (final t in todos) t.id == updated.id ? updated : t]);

  Future<void> toggleTodo(Todo todo) async {
    _replace(todo.copyWith(isCompleted: !todo.isCompleted));
    try {
      _replace(await Api.instance.toggleTodo(todo.id));
    } catch (e) {
      if (mounted) showError(context, e);
      await reload();
    }
  }

  Future<void> editTodo(Todo todo) async {
    final saved = await showTodoForm(context, categories: categories, todo: todo);
    // Tanggal/kategori bisa berubah sehingga tidak lagi cocok dengan filter → muat ulang
    if (saved != null) await reload();
  }

  Future<void> deleteTodo(Todo todo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('"${todo.title}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => todos = todos.where((t) => t.id != todo.id).toList());
    try {
      await Api.instance.deleteTodo(todo.id);
    } catch (e) {
      if (mounted) showError(context, e);
      await reload();
    }
  }
}
