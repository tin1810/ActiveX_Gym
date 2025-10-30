import '../models/er_models.dart';

class MockAuthService {
  MockAuthService._();
  static final MockAuthService instance = MockAuthService._();

  // Default to normal user; you can switch with signInAsTrainer for demo
  UserModel _currentUser = UserModel(id: 'u1', name: 'Willam', email: 'willam@example.com', role: 'user', goal: 'Lose 5kg');

  UserModel get currentUser => _currentUser;

  bool get isTrainer => _currentUser.role.toLowerCase() == 'trainer';
  bool get isAdmin => _currentUser.role.toLowerCase() == 'admin';

  void signInAsUser(UserModel user) {
    _currentUser = user;
  }

  // For demo only
  void signInAsTrainer() {
    _currentUser = UserModel(id: 't1', name: 'Coach Amy', email: 'amy@example.com', role: 'trainer');
  }

  // Mock email/password sign in with role selection
  Future<UserModel> signIn({required String email, required String password}) async {
    // no real verification; simulate latency
    await Future.delayed(const Duration(milliseconds: 250));
    // Sample login rule: if email contains 'trainer' -> trainer; if contains 'admin' -> admin; else user
    final lower = email.toLowerCase();
    if (lower.contains('admin')) {
      _currentUser = UserModel(id: 'a1', name: 'Admin', email: email, role: 'admin');
    } else if (lower.contains('trainer')) {
      _currentUser = UserModel(id: 't1', name: 'Coach Amy', email: email, role: 'trainer');
    } else {
      _currentUser = UserModel(id: 'u1', name: 'Willam', email: email, role: 'user');
    }
    return _currentUser;
  }

  Future<UserModel> register({required String name, required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = UserModel(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, email: email, role: 'user');
    return _currentUser;
  }

  void signOut() {
    _currentUser = UserModel(id: 'u1', name: 'Guest', email: 'guest@example.com', role: 'user');
  }
}


