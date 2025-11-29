import '../models/er_models.dart';
import 'network_service.dart';

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
    
    // Admin account: static email check
    if (lower == 'admin@gmail.com' || lower.contains('admin')) {
      _currentUser = UserModel(id: 'a1', name: 'Admin', email: lower, role: 'admin');
      return _currentUser;
    }
    
    // Look up all users/trainers in mock API (including trainers created by admin)
    final users = await const ApiServiceFor().fetchUsers();
    final match = users.where((u) => u.email.toLowerCase().trim() == lower).toList();
    if (match.isEmpty) {
      throw Exception('No user account found for $email. Please sign up first.');
    }
    final u = match.first;
    
    // Handle trainer accounts created by admin - validate password
    if (u.role.toLowerCase() == 'trainer') {
      final storedPassword = u.password ?? '';
      // If password is set, it must match; if empty/null, allow login (for backward compatibility)
      if (storedPassword.isEmpty || storedPassword == password) {
        _currentUser = UserModel(id: u.id, name: u.name, email: u.email, role: 'trainer');
        return _currentUser;
      }
      throw Exception('Incorrect password');
    }
    
    // Regular users: no strict password validation in mock
    _currentUser = UserModel(id: u.id, name: u.name, email: u.email, role: 'user', goal: u.goal);
    return _currentUser;
  }

  Future<UserModel> register({required String name, required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = UserModel(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, email: email, role: 'user');
    // persist to mock api users list so trainers can assign in dropdowns
    await const ApiServiceFor().addUser(_currentUser);
    return _currentUser;
  }

  void signOut() {
    _currentUser = UserModel(id: 'u1', name: 'Guest', email: 'guest@example.com', role: 'user');
  }
}


