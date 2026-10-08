import 'package:flutter/foundation.dart';

import 'api.dart';
import 'models.dart';

/// offline = token ada tapi server tak terjangkau saat membuka aplikasi.
enum AuthStatus { loading, offline, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController() {
    Api.instance.onUnauthorized = () => _set(null);
  }

  final _api = Api.instance;
  AuthStatus status = AuthStatus.loading;
  User? user;

  void _set(User? u) {
    user = u;
    status = u == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  /// Pulihkan sesi dari token tersimpan agar tidak perlu login ulang.
  Future<void> restore() async {
    status = AuthStatus.loading;
    notifyListeners();
    if (!await _api.loadToken()) return _set(null);
    try {
      _set(await _api.me());
    } on ApiException catch (e) {
      if (e.status == 0) {
        // Jangan hapus token hanya karena offline
        status = AuthStatus.offline;
        notifyListeners();
      } else {
        _set(null);
      }
    }
  }

  Future<void> login(String email, String password) async => _set(await _api.login(email, password));

  Future<void> register(String name, String email, String password, String confirmation) async =>
      _set(await _api.register(name, email, password, confirmation));

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    _set(null);
  }
}
