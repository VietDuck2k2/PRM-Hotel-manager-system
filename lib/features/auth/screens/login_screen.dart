import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../session_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_enums.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../../../shared/widgets/loading_overlay.dart';

/// Login screen. Entry point for all roles.
/// Owner: Member 1
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final session = context.read<SessionProvider>();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    try {
      final success = await session.login(username, password);
      if (!mounted) return;
      if (!success) {
        _showError('Invalid credentials or inactive account.');
        return;
      }
      _navigateToDashboard(session.role);
    } catch (_) {
      if (mounted) {
        _showError('Unable to login right now. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard(StaffRole? role) {
    switch (role) {
      case StaffRole.admin:
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        return;
      case StaffRole.receptionist:
        Navigator.pushReplacementNamed(
            context, AppRoutes.receptionistDashboard);
        return;
      case StaffRole.housekeeping:
        Navigator.pushReplacementNamed(
            context, AppRoutes.housekeepingDashboard);
        return;
      case null:
        _showError('Unable to determine user role. Please login again.');
    }
  }

  void _showError(String message) {
    ErrorSnackbar.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingText: 'Signing in...',
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.hotel,
                          size: 64, color: Color(0xFF1A6B8A)),
                      const SizedBox(height: 8),
                      const Text(
                        'Hotel Management System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _usernameCtrl,
                        focusNode: _usernameFocus,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_passwordFocus),
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        focusNode: _passwordFocus,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (v.length < 4) {
                            return 'Password must be at least 4 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Login',
                        onPressed: _submit,
                        isLoading: _isLoading,
                        icon: Icons.login,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Demo accounts:\nadmin / admin123\nreceptionist / recep123\nhousekeeping / house123',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
