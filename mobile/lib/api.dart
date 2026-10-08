import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

/// Bisa di-override saat build: flutter build apk --dart-define=API_URL=http://10.0.2.2:8020/api
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://api-todo.inovasionline.com/api');

class ApiException implements Exception {
  final String message;
  final int status;
  final Map<String, List<String>> errors;

  const ApiException(this.message, this.status, [this.errors = const {}]);

  /// Pesan validasi pertama untuk field tertentu, atau pesan umum.
  String messageFor(String field) => errors[field]?.first ?? message;

  @override
  String toString() => message;
}

/// Klien REST untuk backend Laravel. Aplikasi mobile memakai bearer token Sanctum
/// (disimpan terenkripsi di Keystore Android), jadi login bertahan sampai logout.
class Api {
  Api._();
  static final instance = Api._();

  static const _tokenKey = 'todo_token';
  final _storage = const FlutterSecureStorage();
  final _client = http.Client();
  String? _token;

  /// Dipanggil saat token ditolak (401) agar UI kembali ke layar login.
  void Function()? onUnauthorized;

  Future<bool> loadToken() async {
    _token = await _storage.read(key: _tokenKey);
    return _token != null;
  }

  Future<void> _saveToken(String? token) async {
    _token = token;
    if (token == null) {
      await _storage.delete(key: _tokenKey);
    } else {
      await _storage.write(key: _tokenKey, value: token);
    }
  }

  Future<dynamic> _request(String method, String path, {Map<String, String>? query, Object? body}) async {
    final uri = Uri.parse('$apiUrl$path').replace(queryParameters: (query?.isEmpty ?? true) ? null : query);
    final req = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      });
    if (body != null) req.body = jsonEncode(body);

    http.Response res;
    try {
      res = await http.Response.fromStream(await _client.send(req).timeout(const Duration(seconds: 20)));
    } catch (_) {
      throw const ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet.', 0);
    }

    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      data = null;
    }

    if (res.statusCode >= 400) {
      if (res.statusCode == 401 && _token != null) {
        await _saveToken(null);
        onUnauthorized?.call();
      }
      final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
      final errors = <String, List<String>>{};
      final raw = map['errors'];
      if (raw is Map) {
        raw.forEach((k, v) => errors['$k'] = (v as List).map((e) => '$e').toList());
      }
      throw ApiException(map['message'] as String? ?? 'Terjadi kesalahan.', res.statusCode, errors);
    }
    return data;
  }

  // ---- Auth ----

  Future<User> login(String email, String password) async {
    final r = await _request('POST', '/login', body: {'email': email, 'password': password, 'device_name': 'android'});
    await _saveToken(r['token'] as String);
    return User.fromJson(r['user'] as Map<String, dynamic>);
  }

  Future<User> register(String name, String email, String password, String passwordConfirmation) async {
    final r = await _request('POST', '/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'device_name': 'android',
    });
    await _saveToken(r['token'] as String);
    return User.fromJson(r['user'] as Map<String, dynamic>);
  }

  Future<User> me() async {
    final r = await _request('GET', '/me');
    return User.fromJson(r['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/logout');
    } finally {
      await _saveToken(null);
    }
  }

  // ---- Kategori ----

  Future<List<Category>> categories() async {
    final r = await _request('GET', '/categories');
    return (r['data'] as List).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Category> createCategory(String name, String color) async {
    final r = await _request('POST', '/categories', body: {'name': name, 'color': color});
    return Category.fromJson(r['data'] as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) => _request('DELETE', '/categories/$id');

  // ---- Tugas ----

  List<Todo> _todos(dynamic r) => (r['data'] as List).map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();

  Future<List<Todo>> todos([TodoFilters filters = const TodoFilters()]) async =>
      _todos(await _request('GET', '/todos', query: filters.toQuery()));

  Future<List<Todo>> todayTodos(String date) async => _todos(await _request('GET', '/todos/today', query: {'date': date}));

  Future<Todo> createTodo(TodoInput data) async {
    final r = await _request('POST', '/todos', body: data.toJson());
    return Todo.fromJson(r['data'] as Map<String, dynamic>);
  }

  Future<Todo> updateTodo(int id, TodoInput data) async {
    final r = await _request('PATCH', '/todos/$id', body: data.toJson());
    return Todo.fromJson(r['data'] as Map<String, dynamic>);
  }

  Future<Todo> toggleTodo(int id) async {
    final r = await _request('PATCH', '/todos/$id/toggle');
    return Todo.fromJson(r['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTodo(int id) => _request('DELETE', '/todos/$id');
}
