import 'package:flutter/material.dart';

import '../api.dart';
import '../date_utils.dart';
import '../models.dart';

/// Bottom sheet tambah / ubah tugas. Mengembalikan Todo yang tersimpan, atau null jika batal.
Future<Todo?> showTodoForm(
  BuildContext context, {
  required List<Category> categories,
  Todo? todo,
  String? defaultDate,
  int? defaultCategoryId,
}) {
  return showModalBottomSheet<Todo>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _TodoForm(
      categories: categories,
      todo: todo,
      defaultDate: defaultDate,
      defaultCategoryId: defaultCategoryId,
    ),
  );
}

class _TodoForm extends StatefulWidget {
  const _TodoForm({required this.categories, this.todo, this.defaultDate, this.defaultCategoryId});

  final List<Category> categories;
  final Todo? todo;
  final String? defaultDate;
  final int? defaultCategoryId;

  @override
  State<_TodoForm> createState() => _TodoFormState();
}

class _TodoFormState extends State<_TodoForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.todo?.title);
  late final _description = TextEditingController(text: widget.todo?.description);
  late String _dueDate = widget.todo?.dueDate ?? widget.defaultDate ?? todayIso();
  late int? _categoryId = widget.todo != null ? widget.todo!.categoryId : widget.defaultCategoryId;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.todo != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseIsoDate(_dueDate),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) setState(() => _dueDate = toIsoDate(picked));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final input = TodoInput(
      title: _title.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      dueDate: _dueDate,
      categoryId: _categoryId,
    );
    try {
      final saved =
          _isEdit ? await Api.instance.updateTodo(widget.todo!.id, input) : await Api.instance.createTodo(input);
      if (mounted) Navigator.pop(context, saved);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Respons server tidak dikenali. Tarik ke bawah untuk memuat ulang.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kategori yang sudah dihapus tidak boleh jadi nilai dropdown
    final validCategory = widget.categories.any((c) => c.id == _categoryId) ? _categoryId : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(_isEdit ? 'Ubah Tugas' : 'Tugas Baru', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              autofocus: !_isEdit,
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder(), counterText: ''),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 4,
              maxLines: 10,
              maxLength: descriptionMax,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                hintText: 'Detail, langkah-langkah, tautan, dll.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: validCategory,
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text(uncategorizedLabel)),
                for (final c in widget.categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(children: [
                      CircleAvatar(radius: 5, backgroundColor: c.colorValue),
                      const SizedBox(width: 8),
                      Text(c.name),
                    ]),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(formatLongDate(_dueDate)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: Text(_saving ? 'Menyimpan…' : (_isEdit ? 'Simpan' : 'Tambah')),
            ),
          ],
        ),
      ),
    );
  }
}
