import 'package:flutter/material.dart';

import '../auth.dart';
import 'categories_screen.dart';
import 'tasks_screen.dart';
import 'today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.auth});

  final AuthController auth;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _todayKey = GlobalKey<TodayScreenState>();
  final _tasksKey = GlobalKey<TasksScreenState>();
  final _categoriesKey = GlobalKey<CategoriesScreenState>();
  int _index = 0;

  static const _titles = ['Beranda', 'Tugas', 'Kategori'];

  void _onDestinationSelected(int i) {
    setState(() => _index = i);
    // Data bisa berubah di tab lain (mis. kategori dihapus) → segarkan saat dibuka
    switch (i) {
      case 0:
        _todayKey.currentState?.reload();
      case 1:
        _tasksKey.currentState?.reload();
      case 2:
        _categoriesKey.currentState?.reload();
    }
  }

  void _onAdd() => switch (_index) {
        0 => _todayKey.currentState?.addTodo(),
        1 => _tasksKey.currentState?.addTodo(),
        _ => _categoriesKey.currentState?.addCategory(),
      };

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: Text('Anda masuk sebagai ${widget.auth.user?.email}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (ok == true) await widget.auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [IconButton(icon: const Icon(Icons.logout), tooltip: 'Keluar', onPressed: _confirmLogout)],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          TodayScreen(key: _todayKey, user: widget.auth.user!),
          TasksScreen(key: _tasksKey),
          CategoriesScreen(key: _categoriesKey),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        tooltip: _index == 2 ? 'Kategori baru' : 'Tugas baru',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tugas'),
          NavigationDestination(icon: Icon(Icons.label_outline), selectedIcon: Icon(Icons.label), label: 'Kategori'),
        ],
      ),
    );
  }
}
