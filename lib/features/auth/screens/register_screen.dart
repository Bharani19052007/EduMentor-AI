import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _preparationPath = 'neet';

  @override
  void dispose() {
    _nameController.dispose();
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

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: 'student', // Default role for registration is student
        name: _nameController.text.trim(),
        preparationPath: _preparationPath,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please check your email to verify (if enabled) or login.')),
      );
      
      // Go to login screen to login with new credentials (or we could auto login, but email confirmation might be required)
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Create Account',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign up to get started',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              
              // Preparation Path Toggle
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
                        onTap: () => setState(() => _preparationPath = 'neet'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _preparationPath == 'neet' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _preparationPath == 'neet'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : [],
                          ),
                          child: Text(
                            'NEET Aspirant',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _preparationPath == 'neet' ? colorScheme.primary : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _preparationPath = 'jee'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _preparationPath == 'jee' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _preparationPath == 'jee'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : [],
                          ),
                          child: Text(
                            'JEE Aspirant',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _preparationPath == 'jee' ? colorScheme.primary : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Full Name Input
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(LucideIcons.user),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                  hintText: 'Create a password',
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
              
              const SizedBox(height: 32),
              
              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
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
                        'Sign Up',
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
              
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Already have an account?', style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
