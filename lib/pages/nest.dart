import 'package:flutter/material.dart';
import 'dart:async';
import 'Nest/join_screen.dart';



class NestApp extends StatelessWidget {
  const NestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nest Communication',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// Professional splash screen with nested animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();

    // Controller for all animations (duration 2.5s for professional reveal)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Fade in from 0 to 1 (smooth)
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    // Scale from 0.85 to 1.0 (gentle pop)
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic)),
    );

    // Subtle slide up for tagline (10px offset)
    _slideUp = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.9, curve: Curves.easeOutQuart)),
    );

    // Start animation
    _controller.forward();

    // Navigate to main screen after animation + delay (total visible ~3.2s)
    Timer(const Duration(milliseconds: 3400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (_, a, __, child) {
              return FadeTransition(opacity: a, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FE), // soft background like nest/communication
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo + brand container
                      Transform.scale(
                        scale: _scaleIn.value,
                        child: Opacity(
                          opacity: _fadeIn.value,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(48),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo placeholder — replace with your actual asset
                                // (using a nested circle + icon to represent "nest")
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2B5F8A), Color(0xFF4A90E2)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 70,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Brand name "Nest"
                                const Text(
                                  'Nest',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.5,
                                    color: Color(0xFF1E2F4D),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Brand line / descriptor
                                const Text(
                                  'communication',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF4F6F8F),
                                    letterSpacing: 2.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Tagline with slide + fade (professional touch)
                      Transform.translate(
                        offset: Offset(0, _slideUp.value),
                        child: Opacity(
                          opacity: _fadeIn.value * 0.9, // slightly more subtle
                          child: const Text(
                            'connect • share • grow',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF3A5770),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Subtle animated indicator (progress)
                      Opacity(
                        opacity: _fadeIn.value * 0.7,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dummy main screen (after splash)
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Automatically redirect to JoinScreen after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 1), () {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => JoinScreen(),
              transitionDuration: const Duration(milliseconds: 800),
              transitionsBuilder: (_, a, __, child) {
                return FadeTransition(opacity: a, child: child);
              },
            ),
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nest'),
        backgroundColor: const Color(0xFFE1EAF2),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE1EAF2), Color(0xFFF5F9FF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.done_outline, size: 80, color: Color(0xFF2B5F8A)),
              const SizedBox(height: 24),
              Text(
                'Welcome to Nest',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF1E2F4D),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Your communication hub is ready.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF4F6F8F), fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
              // Loading indicator for smooth transition
              const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2B5F8A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}