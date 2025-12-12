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

  // Login via API
  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      // Call API login endpoint
      final apiResponse = await activeXGymApiService.login(
        email: email,
        password: password,
      );

      if (apiResponse.success && apiResponse.data != null) {
        // API login successful
        final authData = apiResponse.data!;
        _currentUser = authData.user;
        return _currentUser;
      } else {
        // API returned error - build comprehensive error message
        String errorMessage = apiResponse.message ?? '';
        
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) => e.message)
              .where((m) => m.isNotEmpty)
              .toList();
          
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.toString();
          }
        }
        
        if (errorMessage.isEmpty) {
          errorMessage = 'Login failed. Please check your credentials and try again.';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Re-throw with better context if it's not already an Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Login failed: $e');
    }
  }

  Future<UserModel> register({required String name, required String email, required String password}) async {
    try {
      // Register via API only (no SQLite)
      final apiResponse = await activeXGymApiService.register(
        name: name,
        email: email,
        password: password,
      );

      if (apiResponse.success && apiResponse.data != null) {
        // API registration successful
        final authData = apiResponse.data!;
        _currentUser = authData.user;
        return _currentUser;
      } else {
        // API returned error - build comprehensive error message
        String errorMessage = apiResponse.message ?? '';
        
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                // Format: "Field: Message" or just "Message"
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        
        if (errorMessage.isEmpty) {
          errorMessage = 'Registration failed. Please try again.';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Re-throw with better context if it's not already an Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      // Call API logout endpoint
      await activeXGymApiService.logout();
    } catch (e) {
      // Log error but continue with local signout
      print('Logout API error: $e');
    } finally {
      // Always clear local user state
      _currentUser = UserModel(id: 'u1', name: 'Guest', email: 'guest@example.com', role: 'user');
    }
  }
}


