

import 'package:supabase_flutter/supabase_flutter.dart';


class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<User?> get authState =>
      _client.auth.onAuthStateChange.map((data) => data.session?.user);

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();
}
