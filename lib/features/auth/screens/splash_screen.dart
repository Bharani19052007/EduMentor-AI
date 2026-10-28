import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          final authService = AuthService();
          final user = authService.currentUser;
          if (user != null) {
            final role = authService.currentUserRole;
            if (role == 'admin') {
              context.go('/admin/home');
            } else {
              context.go('/home');
            }
          } else {
            context.go('/onboarding');
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Animated Blobs (Matching Onboarding for seamless transition)
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            left: -size.width * 0.3,
            child: Container(
              width: size.width,
              height: size.width,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Glassmorphism Blur Layer
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          // Foreground Content
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Glass Logo Container
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.25),
                                blurRadius: 40,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.graduationCap,
                              size: 70,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // App Name
                        Text(
                          'EduMentor AI',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.grey[900],
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            'NEET & JEE PREPARATION',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


