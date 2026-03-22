import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/constants/app_enums.dart';

/// In-memory session state. Holds the currently logged-in user.
/// Cleared on logout. Provided at app root via [ChangeNotifierProvider].
/// Owner: Member 1
class SessionProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  SessionProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  StaffRole? get role => _currentUser?.role;
  int? get userId => _currentUser?.id;
  String? get username => _currentUser?.username;
  String? get fullName => _currentUser?.fullName;

  /// Attempt login. Returns true on success.
  Future<bool> login(String username, String password) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) return false;
    try {
      final user = await _authRepository.login(trimmedUsername, password);
      if (user == null) return false;
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void clearSession() => logout();
}
