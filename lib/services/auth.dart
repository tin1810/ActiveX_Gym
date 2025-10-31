import '../models/er_models.dart';
import 'mock_api.dart';

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
    final lower = email.toLowerCase().trim();
    // Static trainer account (created by admin)
    if (lower == 'trainer@gmail.com') {
      _currentUser = UserModel(id: 't1', name: 'Coach Amy', email: lower, role: 'trainer');
      return _currentUser;
    }
    // Keep simple admin rule for convenience (optional)
    if (lower.contains('admin')) {
      _currentUser = UserModel(id: 'a1', name: 'Admin', email: lower, role: 'admin');
      return _currentUser;
    }
    // Otherwise, look up registered users in mock API (user-only)
    final users = await const MockApiService().fetchUsers();
    final match = users.where((u) => u.email.toLowerCase() == lower).toList();
    if (match.isEmpty) {
      throw Exception('No user account found for $email. Please sign up first.');
    }
    final u = match.first;
    _currentUser = UserModel(id: u.id, name: u.name, email: u.email, role: 'user', goal: u.goal);
    return _currentUser;
  }

  Future<UserModel> register({required String name, required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = UserModel(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, email: email, role: 'user');
    // persist to mock api users list so trainers can assign in dropdowns
    await const MockApiService().addUser(_currentUser);
    return _currentUser;
  }

  void signOut() {
    _currentUser = UserModel(id: 'u1', name: 'Guest', email: 'guest@example.com', role: 'user');
  }
}


