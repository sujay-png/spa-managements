
import 'package:flutter/foundation.dart';
import 'package:ira_spa_webapp/views/service/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AuthController extends ChangeNotifier {
  final AuthService _service = AuthService();

  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
 Map<String,dynamic>?_userProfile;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;

 Map<String, dynamic>? get userProfile => _userProfile;
 String? get userName => _userProfile?['user_name'];
 int? get businessRef {
  final value = _userProfile?['user_businessRef'];

  if (value == null) return null;

  if (value is int) return value;

  return int.tryParse(value.toString());
}


 AuthController() {
    _service.authState.listen((user) async {
      _user = user;
      if (user != null) {
        _userProfile = await _service.fetchUserProfile(user.id);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

 Future<bool> signIn(String email, String password) async {
  _loading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await _service.signIn(
      email.trim(),
      password.trim(),
    );

    _user = response.user;

    if (_user != null) {
      _userProfile = await _service.fetchUserProfile(_user!.id);

      debugPrint("User Profile: $_userProfile");
      debugPrint("Business Ref: ${_userProfile?['user_businessRef']}");
    }

    return true;
  } on AuthException catch (e) {
    _error = e.message;
    return false;
  } finally {
    _loading = false;
    notifyListeners();
  }
}

  Future<void> signOut() => _service.signOut();
}
