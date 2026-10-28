import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'student';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      await authService.signInWithGoogle();

      if (!mounted) return;
      
      final role = authService.currentUserRole;
      if (role == 'admin') {
        context.go('/admin/home');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign In failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      
      final role = authService.currentUserRole;
      if (role == 'admin') {
        context.go('/admin/home');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Logo/Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.graduationCap,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              // Header
              Text(
                'Welcome Back',
                style: theme.textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Login to continue your preparation',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Role Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = 'student'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _role == 'student' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _role == 'student'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : [],
                          ),
                          child: Text(
                            'Student',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _role == 'student' ? colorScheme.primary : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = 'admin'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _role == 'admin' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _role == 'admin'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : [],
                          ),
                          child: Text(
                            'Admin',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _role == 'admin' ? colorScheme.primary : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Email Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(LucideIcons.mail),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(LucideIcons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              if (_role == 'student') ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to forgot password
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 32),
              ],
              
              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 16),
              
              // Google Sign In Button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                icon: Image.asset('assets/images/google_logo.png', height: 24),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              ),
              
              if (_role == 'student') ...[
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Don\'t have an account?', style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: () {
                        context.push('/register');
                      },
                      child: Text(
                        'Register',
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
