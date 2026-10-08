import 'package:flutter_test/flutter_test.dart';
import 'package:todo_mobile/models.dart';

void main() {
  test('Todo.fromJson membaca kategori "Tanpa Kategori"', () {
    final todo = Todo.fromJson({
      'id': 1,
      'title': 'Beli sayur',
      'description': 'Baris 1\nBaris 2',
      'due_date': '2026-10-08',
      'is_completed': false,
      'category_id': null,
      'category': {'id': null, 'name': uncategorizedLabel, 'color': '#9ca3af'},
    });
    expect(todo.category.id, isNull);
    expect(todo.category.colorValue.toARGB32(), 0xFF9CA3AF);
    expect(todo.copyWith(isCompleted: true).isCompleted, isTrue);
  });

  test('Todo baru dengan is_completed null dibaca sebagai belum selesai', () {
    final todo = Todo.fromJson({
      'id': 2,
      'title': 'Baru',
      'description': null,
      'due_date': '2026-10-08',
      'is_completed': null,
      'category_id': null,
      'category': {'id': null, 'name': uncategorizedLabel, 'color': '#9ca3af'},
    });
    expect(todo.isCompleted, isFalse);
  });

  test('TodoFilters hanya mengirim parameter yang diisi', () {
    expect(const TodoFilters(search: '', categoryId: 'none', month: 10, year: 2026).toQuery(),
        {'category_id': 'none', 'month': '10', 'year': '2026'});
  });
}
