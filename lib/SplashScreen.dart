import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iss_app/home_page.dart';



class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  late AnimationController _bottomImageController;
  late Animation<Offset> _bottomImageSlide;
  late Animation<double> _bottomImageFade;

  @override
  void initState() {
    super.initState();


    // 🎬 Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _logoScale =
        CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack);
    _logoFade =
        CurvedAnimation(parent: _logoController, curve: Curves.easeIn);

    // 🎬 Bottom image animation
    _bottomImageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _bottomImageSlide = Tween<Offset>(
      begin: const Offset(0, 1), // starts offscreen bottom
      end: Offset.zero, // ends in normal position
    ).animate(CurvedAnimation(
      parent: _bottomImageController,
      curve: Curves.easeOutCubic,
    ));
    _bottomImageFade =
        CurvedAnimation(parent: _bottomImageController, curve: Curves.easeIn);

    // ▶️ Start both animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _bottomImageController.forward();
    });

    // ⏳ Navigate to Dashboard after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(),),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _bottomImageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF4500),
              Color(0xFFFFFF00),
              Color(0xFFFFFFFF),
              Color(0xFF00BFFF),
              Color(0xFFFFD700),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 🌀 Main centered logo (fade + scale)
            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoFade,
                child: Image.asset(
                  'assets/images/icon.png',
                  width: 300,
                ),
              ),
            ),

            // 🌊 Second image slides up from bottom
            Positioned(
              bottom: 100,
              child: SlideTransition(
                position: _bottomImageSlide,
                child: FadeTransition(
                  opacity: _bottomImageFade,
                  child: Image.asset(
                    'assets/images/issb.png',
                    width: 350,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


