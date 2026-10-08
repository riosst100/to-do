import 'package:flutter/material.dart';

import '../api.dart';
import '../date_utils.dart';
import '../models.dart';
import '../widgets/message_view.dart';
import '../widgets/todo_actions.dart';
import '../widgets/todo_form_sheet.dart';
import '../widgets/todo_tile.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.user});

  final User user;

  @override
  State<TodayScreen> createState() => TodayScreenState();
}

class TodayScreenState extends State<TodayScreen> with TodoListActions {
  bool _loading = true;
  String? _error;
  String _today = todayIso();

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  Future<void> reload() async {
    _today = todayIso(); // aplikasi bisa terbuka melewati tengah malam
    try {
      final results = await Future.wait([Api.instance.todayTodos(_today), Api.instance.categories()]);
      if (!mounted) return;
      setState(() {
        todos = results[0] as List<Todo>;
        categories = results[1] as List<Category>;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> addTodo() async {
    final saved = await showTodoForm(context, categories: categories, defaultDate: _today);
    if (saved != null) await reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = todos.where((t) => t.isCompleted).length;
    final progress = todos.isEmpty ? 0.0 : done / todos.length;
    final firstName = widget.user.name.split(' ').first;

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text('Halo, $firstName 👋', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          Text(formatLongDate(_today), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text('Tugas hari ini', style: theme.textTheme.titleMedium)),
                    Text('$done/${todos.length} selesai', style: theme.textTheme.bodySmall),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: progress, minHeight: 8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            MessageView(text: _error!, action: TextButton(onPressed: reload, child: const Text('Coba lagi')))
          else if (todos.isEmpty)
            const MessageView(text: 'Belum ada tugas untuk hari ini. Ketuk + untuk menambah.')
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, t) in todos.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    TodoTile(
                      key: ValueKey(t.id),
                      todo: t,
                      showDate: false,
                      onToggle: () => toggleTodo(t),
                      onEdit: () => editTodo(t),
                      onDelete: () => deleteTodo(t),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
