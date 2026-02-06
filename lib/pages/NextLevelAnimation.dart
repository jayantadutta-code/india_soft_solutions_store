import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart'; // replace with your actual home page file

class NextLevelAnimation extends StatefulWidget {
  const NextLevelAnimation({Key? key}) : super(key: key);

  @override
  State<NextLevelAnimation> createState() => _NextLevelAnimationState();
}

class _NextLevelAnimationState extends State<NextLevelAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> androidAnim, appleAnim, globeAnim, monitorAnim;
  late Animation<double> fadeIn;

  bool showFinalLogo = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    androidAnim =
        Tween(begin: const Offset(-2, 0), end: Offset(-0.2, 0))
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    appleAnim =
        Tween(begin: const Offset(2, 0), end: Offset(0.2, 0))
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    globeAnim =
        Tween(begin: const Offset(0, -2), end: Offset(0, -0.1))
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    monitorAnim =
        Tween(begin: const Offset(0, 2), end: Offset(0, 0.15))
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0)),
    );

    _controller.forward();

    Timer(const Duration(seconds: 5), () {
      setState(() => showFinalLogo = true);
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
      backgroundColor: Colors.white,

      // ---------------- BACK BUTTON ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red, size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      // ------------------------------------------------

      body: Center(
        child: showFinalLogo
            ? FadeTransition(
          opacity: fadeIn,
          child: Image.asset(
            'assets/images/icon.png',
            width: 180,
            height: 180,
          ),
        )
            : Stack(
          alignment: Alignment.center,
          children: [
            SlideTransition(
              position: monitorAnim,
              child: Image.asset('assets/images/monitor.png', width: 170),
            ),
            SlideTransition(
              position: globeAnim,
              child: Image.asset('assets/images/globe.png', width: 100),
            ),
            SlideTransition(
              position: androidAnim,
              child: Image.asset('assets/images/android.png', width: 60),
            ),
            SlideTransition(
              position: appleAnim,
              child: Image.asset('assets/images/apple.png', width: 60),
            ),
          ],
        ),
      ),
    );
  }
}
