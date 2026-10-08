import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets/message_view.dart';
import '../widgets/todo_actions.dart';

const categoryColors = ['#6366f1', '#ec4899', '#f59e0b', '#10b981', '#0ea5e9', '#ef4444', '#8b5cf6', '#64748b'];

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => CategoriesScreenState();
}

class CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    try {
      final list = await Api.instance.categories();
      if (mounted) {
        setState(() {
          _categories = list;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> addCategory() async {
    final created = await showDialog<Category>(context: context, builder: (_) => const _CategoryDialog());
    if (created != null) await reload();
  }

  Future<void> _delete(Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kategori?'),
        content: Text('Tugas di kategori "${c.name}" akan dipindah ke "$uncategorizedLabel".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _categories = _categories.where((x) => x.id != c.id).toList());
    try {
      await Api.instance.deleteCategory(c.id);
    } catch (e) {
      if (mounted) showError(context, e);
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            MessageView(text: _error!, action: TextButton(onPressed: reload, child: const Text('Coba lagi')))
          else if (_categories.isEmpty)
            const MessageView(text: 'Belum ada kategori. Ketuk + untuk membuat.')
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (final (i, c) in _categories.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(radius: 8, backgroundColor: c.colorValue),
                    title: Text(c.name),
                    subtitle: c.todosCount == null
                        ? null
                        : Text('${c.todosCount} tugas · ${c.pendingCount ?? 0} belum selesai'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: theme.colorScheme.onSurfaceVariant,
                      tooltip: 'Hapus',
                      onPressed: () => _delete(c),
                    ),
                  ),
                ],
              ]),
            ),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog();

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _name = TextEditingController();
  String _color = categoryColors.first;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return setState(() => _error = 'Nama wajib diisi');
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final c = await Api.instance.createCategory(_name.text.trim(), _color);
      if (mounted) Navigator.pop(context, c);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.messageFor('name'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Kategori Baru'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 50,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(labelText: 'Nama', border: const OutlineInputBorder(), errorText: _error),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final hex in categoryColors)
              GestureDetector(
                onTap: () => setState(() => _color = hex),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: parseHexColor(hex),
                  child: _color == hex ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              ),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Menyimpan…' : 'Simpan')),
        ],
      );
}
