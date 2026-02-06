import 'dart:math';
import 'package:flutter/material.dart';

class FullAnimation extends StatefulWidget {
  const FullAnimation({super.key});

  @override
  State<FullAnimation> createState() => _FullAnimationState();
}

class _FullAnimationState extends State<FullAnimation>
    with TickerProviderStateMixin {
  late AnimationController controller;
  late AnimationController logoController;

  Alignment rotateAlignment(Alignment a, double angle) {
    double x = a.x * cos(angle) - a.y * sin(angle);
    double y = a.x * sin(angle) + a.y * cos(angle);
    return Alignment(x, y);
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.8,
      upperBound: 1.2,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    logoController.dispose();
    super.dispose();
  }

  Widget gradientBox({
    required double angle,
    required Alignment begin,
    required Alignment end,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double t = controller.value * 2 * pi;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [Colors.red, Colors.yellow],
              begin: rotateAlignment(begin, angle * t),
              end: rotateAlignment(end, angle * t),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: gradientBox(
                        angle: 1,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    Expanded(
                      child: gradientBox(
                        angle: -1,
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: gradientBox(
                        angle: -1,
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    Expanded(
                      child: gradientBox(
                        angle: 1,
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ⭐ CENTER LOGO ANIMATION ⭐
          Center(
            child: ScaleTransition(
              scale: logoController,
              child: SizedBox(
                width: 300,
                height: 300,
                child: Image.asset("assets/images/icon.png"),
              ),
            ),
          ),

          // ⭐ ICON BUTTON ADDED ⭐
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 600), // move button below logo
              child: IconButton(
                iconSize: 50,
                color: Colors.white,
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
