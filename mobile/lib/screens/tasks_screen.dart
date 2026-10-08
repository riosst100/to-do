import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../date_utils.dart';
import '../models.dart';
import '../widgets/message_view.dart';
import '../widgets/todo_actions.dart';
import '../widgets/todo_form_sheet.dart';
import '../widgets/todo_tile.dart';

enum TimeMode { all, date, month, year }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> with TodoListActions {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  String? _error;
  int _requestId = 0;

  String _search = '';
  String _categoryId = ''; // '' = semua, 'none' = Tanpa Kategori
  String? _status; // null | pending | completed
  TimeMode _timeMode = TimeMode.all;
  DateTime _date = DateTime.now();
  DateTime _month = DateTime.now();
  int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  TodoFilters get _filters => TodoFilters(
        search: _search,
        categoryId: _categoryId,
        status: _status,
        date: _timeMode == TimeMode.date ? toIsoDate(_date) : null,
        month: _timeMode == TimeMode.month ? _month.month : null,
        year: switch (_timeMode) {
          TimeMode.month => _month.year,
          TimeMode.year => _year,
          _ => null,
        },
      );

  @override
  Future<void> reload() async {
    final id = ++_requestId; // abaikan respons lama jika filter berubah cepat
    try {
      final results = await Future.wait([Api.instance.todos(_filters), Api.instance.categories()]);
      if (!mounted || id != _requestId) return;
      setState(() {
        todos = results[0] as List<Todo>;
        categories = results[1] as List<Category>;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted && id == _requestId) setState(() => _error = e.message);
    } finally {
      if (mounted && id == _requestId) setState(() => _loading = false);
    }
  }

  void _update(VoidCallback change) {
    setState(change);
    reload();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _update(() => _search = value.trim()));
  }

  bool get _hasFilter => _search.isNotEmpty || _categoryId.isNotEmpty || _status != null || _timeMode != TimeMode.all;

  void _resetFilters() {
    _searchController.clear();
    _update(() {
      _search = '';
      _categoryId = '';
      _status = null;
      _timeMode = TimeMode.all;
    });
  }

  Future<void> addTodo() async {
    final saved = await showTodoForm(
      context,
      categories: categories,
      defaultDate: _timeMode == TimeMode.date ? toIsoDate(_date) : null,
      defaultCategoryId: int.tryParse(_categoryId),
    );
    if (saved != null) await reload();
  }

  // ---- Pemilih waktu ----

  Future<void> _chooseTimeMode() async {
    final mode = await showModalBottomSheet<TimeMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final (m, label) in [
            (TimeMode.all, 'Semua waktu'),
            (TimeMode.date, 'Per tanggal'),
            (TimeMode.month, 'Per bulan'),
            (TimeMode.year, 'Per tahun'),
          ])
            ListTile(
              title: Text(label),
              trailing: _timeMode == m ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, m),
            ),
        ]),
      ),
    );
    if (mode == null || !mounted) return;
    switch (mode) {
      case TimeMode.all:
        _update(() => _timeMode = mode);
      case TimeMode.date:
        final d = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(1970),
          lastDate: DateTime(2100, 12, 31),
        );
        if (d != null) {
          _update(() {
            _timeMode = mode;
            _date = d;
          });
        }
      case TimeMode.month:
        final m = await _pickMonth();
        if (m != null) {
          _update(() {
            _timeMode = mode;
            _month = m;
          });
        }
      case TimeMode.year:
        final y = await _pickYear();
        if (y != null) {
          _update(() {
            _timeMode = mode;
            _year = y;
          });
        }
    }
  }

  Future<DateTime?> _pickMonth() {
    var year = _month.year;
    final months = DateFormat.MMM('id');
    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Row(children: [
            IconButton(onPressed: () => setLocal(() => year--), icon: const Icon(Icons.chevron_left)),
            Expanded(child: Text('$year', textAlign: TextAlign.center)),
            IconButton(onPressed: () => setLocal(() => year++), icon: const Icon(Icons.chevron_right)),
          ]),
          content: SizedBox(
            width: 300,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var m = 1; m <= 12; m++)
                  ChoiceChip(
                    label: SizedBox(width: 48, child: Text(months.format(DateTime(year, m)), textAlign: TextAlign.center)),
                    selected: _timeMode == TimeMode.month && _month.year == year && _month.month == m,
                    onSelected: (_) => Navigator.pop(ctx, DateTime(year, m)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<int?> _pickYear() {
    final now = DateTime.now().year;
    return showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih tahun'),
        children: [
          for (var y = now - 3; y <= now + 3; y++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, y),
              child: Text('$y', style: TextStyle(fontWeight: y == _year ? FontWeight.bold : null)),
            ),
        ],
      ),
    );
  }

  String get _timeLabel => switch (_timeMode) {
        TimeMode.all => 'Semua waktu',
        TimeMode.date => formatDate(toIsoDate(_date)),
        TimeMode.month => formatMonth(_month.year, _month.month),
        TimeMode.year => '$_year',
      };

  // ---- Tampilan ----

  /// Kelompokkan per kategori; "Tanpa Kategori" selalu di urutan pertama.
  List<({String key, TodoCategory category, List<Todo> todos})> get _groups {
    final map = <String, ({TodoCategory category, List<Todo> todos})>{};
    for (final t in todos) {
      final key = t.category.id == null ? 'none' : '${t.category.id}';
      map.putIfAbsent(key, () => (category: t.category, todos: <Todo>[])).todos.add(t);
    }
    final entries = map.entries.toList()
      ..sort((a, b) {
        if (a.key == 'none') return -1;
        if (b.key == 'none') return 1;
        return a.value.category.name.toLowerCase().compareTo(b.value.category.name.toLowerCase());
      });
    return [for (final e in entries) (key: e.key, category: e.value.category, todos: e.value.todos)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = _groups;
    final categoryLabel = switch (_categoryId) {
      '' => 'Semua kategori',
      'none' => uncategorizedLabel,
      final id => categories.where((c) => '${c.id}' == id).firstOrNull?.name ?? 'Kategori',
    };

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Cari tugas…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              PopupMenuButton<String>(
                onSelected: (v) => _update(() => _categoryId = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: '', child: Text('Semua kategori')),
                  const PopupMenuItem(value: 'none', child: Text(uncategorizedLabel)),
                  for (final c in categories) PopupMenuItem(value: '${c.id}', child: Text(c.name)),
                ],
                child: _FilterChipLabel(label: categoryLabel, active: _categoryId.isNotEmpty),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (v) => _update(() => _status = v.isEmpty ? null : v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: '', child: Text('Semua status')),
                  PopupMenuItem(value: 'pending', child: Text('Belum selesai')),
                  PopupMenuItem(value: 'completed', child: Text('Selesai')),
                ],
                child: _FilterChipLabel(
                  label: switch (_status) { 'pending' => 'Belum selesai', 'completed' => 'Selesai', _ => 'Semua status' },
                  active: _status != null,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _chooseTimeMode,
                borderRadius: BorderRadius.circular(8),
                child: _FilterChipLabel(label: _timeLabel, active: _timeMode != TimeMode.all),
              ),
              if (_hasFilter) TextButton(onPressed: _resetFilters, child: const Text('Reset')),
            ]),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            MessageView(text: _error!, action: TextButton(onPressed: reload, child: const Text('Coba lagi')))
          else if (groups.isEmpty)
            const MessageView(text: 'Tidak ada tugas yang cocok.')
          else
            for (final g in groups)
              Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(children: [
                  Container(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      CircleAvatar(radius: 5, backgroundColor: g.category.colorValue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(g.category.name, style: theme.textTheme.titleSmall)),
                      Text(
                        '${g.todos.where((t) => t.isCompleted).length}/${g.todos.length} selesai',
                        style: theme.textTheme.bodySmall,
                      ),
                    ]),
                  ),
                  for (final (i, t) in g.todos.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    TodoTile(
                      key: ValueKey(t.id),
                      todo: t,
                      showCategory: false,
                      onToggle: () => toggleTodo(t),
                      onEdit: () => editTodo(t),
                      onDelete: () => deleteTodo(t),
                    ),
                  ],
                ]),
              ),
        ],
      ),
    );
  }
}

class _FilterChipLabel extends StatelessWidget {
  const _FilterChipLabel({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? scheme.secondaryContainer : null,
        border: Border.all(color: active ? scheme.secondaryContainer : scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(color: active ? scheme.onSecondaryContainer : null)),
        const SizedBox(width: 4),
        const Icon(Icons.arrow_drop_down, size: 18),
      ]),
    );
  }
}
