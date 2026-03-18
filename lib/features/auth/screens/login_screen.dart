import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../session_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_enums.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/error_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final sessionProvider = context.read<SessionProvider>();
      final success = await sessionProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        final role = sessionProvider.role;
        if (role == StaffRole.admin.name) {
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        } else if (role == StaffRole.receptionist.name) {
          Navigator.pushReplacementNamed(context, AppRoutes.receptionistDashboard);
        } else if (role == StaffRole.housekeeping.name) {
          Navigator.pushReplacementNamed(context, AppRoutes.housekeepingDashboard);
        } else {
          ErrorSnackbar.show(context, 'Unknown role: $role');
        }
      } else {
        ErrorSnackbar.show(context, 'Invalid username or password');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<SessionProvider>().isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hotel_rounded,
                            size: 72,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome Back',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to your HMS account',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Please enter your username' : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Please enter your password' : null,
                          ),
                          const SizedBox(height: 32),
                          PrimaryButton(
                            text: 'Sign In',
                            onPressed: _login,
                          ),
                        ],
                      ),
                    ),
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
