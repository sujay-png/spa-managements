
import 'package:flutter/foundation.dart';
import 'package:ira_spa_webapp/views/service/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AuthController extends ChangeNotifier {
  final AuthService _service = AuthService();

  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  AuthController() {
    _service.authState.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.signIn(email.trim(), password);
      return true;
    } on AuthException catch (e) {
      _error = e.message ?? 'Sign in failed';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => _service.signOut();
}
