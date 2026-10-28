import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Learn with AI',
      'description': 'Get step-by-step solutions for NEET & JEE problems anytime, anywhere.',
      'icon': LucideIcons.bot,
    },
    {
      'title': 'Mock Tests & Analytics',
      'description': 'Practice with real exam patterns and track your performance over time.',
      'icon': LucideIcons.barChart2,
    },
    {
      'title': 'Personalized Resources',
      'description': 'Access curated notes, PDFs, and formula sheets tailored for you.',
      'icon': LucideIcons.bookOpen,
    },
  ];

  void _nextSlide() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go('/login');
    }
  }

  void _skip() {
    context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
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
          // Background Animated Blobs
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
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: InkWell(
                              onTap: _skip,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: constraints.maxHeight > 600 ? constraints.maxHeight * 0.6 : 360,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemCount: _slides.length,
                          itemBuilder: (context, index) {
                            final isCurrentPage = _currentIndex == index;
                            return AnimatedScale(
                              scale: isCurrentPage ? 1.0 : 0.9,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutQuad,
                              child: AnimatedOpacity(
                                opacity: isCurrentPage ? 1.0 : 0.5,
                                duration: const Duration(milliseconds: 300),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 140,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: colorScheme.primary.withValues(alpha: 0.2),
                                                blurRadius: 40,
                                                offset: const Offset(0, 20),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              _slides[index]['icon'] as IconData,
                                              size: 60,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          _slides[index]['title'] as String,
                                          style: theme.textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[900],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _slides[index]['description'] as String,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: 16,
                                            height: 1.5,
                                            color: Colors.grey[700],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _slides.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  height: 6,
                                  width: _currentIndex == index ? 24 : 6,
                                  decoration: BoxDecoration(
                                    color: _currentIndex == index
                                        ? colorScheme.primary
                                        : colorScheme.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [colorScheme.primary, colorScheme.secondary],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _nextSlide,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  _currentIndex == _slides.length - 1 ? 'Get Started' : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
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

