import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/animation.dart';



class BirthdayCountdown extends StatefulWidget {
  const BirthdayCountdown({super.key});

  @override
  State<BirthdayCountdown> createState() => _BirthdayCountdownState();
}

class _BirthdayCountdownState extends State<BirthdayCountdown>
    with SingleTickerProviderStateMixin {
  DateTime? dob;
  DateTime? nextBirthday;
  int daysLeft = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isCelebrating = false;
  double _confettiCount = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFF6C63FF).withAlpha(150),
      end: const Color(0xFFFF6584),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _safeBirthday(int year, DateTime dob) {
    try {
      return DateTime(year, dob.month, dob.day);
    } catch (_) {
      return DateTime(year, 3, 1);
    }
  }

  DateTime calculateNextBirthday(DateTime dob) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    DateTime thisYearBirthday = _safeBirthday(today.year, dob);

    if (!thisYearBirthday.isAfter(todayDate)) {
      return _safeBirthday(today.year + 1, dob);
    }
    return thisYearBirthday;
  }

  bool isBirthdayToday(DateTime dob) {
    final today = DateTime.now();
    return today.day == dob.day && today.month == dob.month;
  }

  void _celebrateBirthday() {
    setState(() {
      _isCelebrating = true;
      _confettiCount = 50;
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isCelebrating = false;
      });
    });
  }

  void updateCountdown(DateTime pickedDob) {
    final nb = calculateNextBirthday(pickedDob);
    final todayDate =
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    setState(() {
      dob = pickedDob;
      nextBirthday = nb;
      daysLeft = nb.difference(todayDate).inDays;

      if (isBirthdayToday(pickedDob)) {
        _celebrateBirthday();
      }
    });
  }

  // Helper function to format dates
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showDatePicker() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF6C63FF),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      updateCountdown(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF6C63FF).withAlpha(26),
                  const Color(0xFFFF6584).withAlpha(10),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Animated Floating Elements
          Positioned.fill(
            child: CustomPaint(
              painter: FloatingElementsPainter(controller: _controller),
            ),
          ),

          // Confetti Animation
          if (_isCelebrating)
            Positioned.fill(
              child: ConfettiAnimation(count: _confettiCount),
            ),

          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

                  // Title with Animation
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Column(
                            children: [
                              Icon(
                                Icons.cake_rounded,
                                size: 60,
                                color: _colorAnimation.value,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Birthday Countdown',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  foreground: Paint()
                                    ..shader = const LinearGradient(
                                      colors: [
                                        Color(0xFF6C63FF),
                                        Color(0xFFFF6584),
                                      ],
                                    ).createShader(
                                      const Rect.fromLTWH(0, 0, 200, 70),
                                    ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Select DOB Card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Select your Date of Birth',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Material(
                          borderRadius: BorderRadius.circular(15),
                          elevation: 0,
                          child: InkWell(
                            onTap: _showDatePicker,
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFFFF6584),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'CHOOSE YOUR BIRTHDAY',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Countdown Display
                  if (dob != null) ...[
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Birthdate Info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _InfoCard(
                                    title: 'Your Birthday',
                                    value: _formatDate(dob!),
                                    icon: Icons.cake_rounded,
                                    color: const Color(0xFF6C63FF),
                                  ),
                                  _InfoCard(
                                    title: 'Next Celebration',
                                    value: _formatDate(nextBirthday!),
                                    icon: Icons.celebration_rounded,
                                    color: const Color(0xFFFF6584),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Days Counter
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6C63FF).withAlpha(26),
                                      const Color(0xFFFF6584).withAlpha(26),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      isBirthdayToday(dob!)
                                          ? '🎉🎂 HAPPY BIRTHDAY! 🎂🎉'
                                          : 'DAYS UNTIL YOUR BIRTHDAY',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6C63FF),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isBirthdayToday(dob!) ? 'TODAY!' : '$daysLeft',
                                      style: TextStyle(
                                        fontSize: 72,
                                        fontWeight: FontWeight.w800,
                                        foreground: Paint()
                                          ..shader = const LinearGradient(
                                            colors: [
                                              Color(0xFF6C63FF),
                                              Color(0xFFFF6584),
                                            ],
                                          ).createShader(
                                            const Rect.fromLTWH(0, 0, 200, 100),
                                          ),
                                      ),
                                    ),
                                    if (!isBirthdayToday(dob!))
                                      Text(
                                        'days',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF666666),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Progress Bar
                              if (!isBirthdayToday(dob!))
                                Column(
                                  children: [
                                    LinearProgressIndicator(
                                      value: 1 - (daysLeft / 365),
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color(0xFFFF6584),
                                      ),
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Progress',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${((1 - (daysLeft / 365)) * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF6C63FF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Empty State
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cake_rounded,
                            size: 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Select your birthday to start the countdown!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingElementsPainter extends CustomPainter {
  final Animation<double> controller;

  FloatingElementsPainter({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withAlpha(10)
      ..style = PaintingStyle.fill;

    final radius = 8.0 + sin(controller.value * 2 * pi) * 4;

    // Draw floating circles
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.1 + 0.8 * sin(controller.value * pi + i * 0.5));
      final y = size.height * (0.1 + 0.8 * cos(controller.value * pi + i * 0.7));

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConfettiAnimation extends StatefulWidget {
  final double count;

  const ConfettiAnimation({super.key, required this.count});

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<ConfettiPiece> pieces = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward();

    _generateConfetti();
  }

  @override
  void didUpdateWidget(covariant ConfettiAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count) {
      _generateConfetti();
    }
  }

  void _generateConfetti() {
    final random = Random();
    pieces = List.generate(
      widget.count.toInt(),
          (index) => ConfettiPiece(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.5 - 0.5,
        speed: 1 + random.nextDouble() * 2,
        color: [
          const Color(0xFF6C63FF),
          const Color(0xFFFF6584),
          const Color(0xFFFFD166),
          const Color(0xFF06D6A0),
          const Color(0xFF118AB2),
        ][random.nextInt(5)],
        size: 4 + random.nextDouble() * 8,
        rotation: random.nextDouble() * 2 * pi,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(
            controller: _controller,
            pieces: pieces,
          ),
        );
      },
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final Animation<double> controller;
  final List<ConfettiPiece> pieces;

  ConfettiPainter({
    required this.controller,
    required this.pieces,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final progress = controller.value;
      final y = piece.y + piece.speed * progress;
      final rotation = piece.rotation + progress * pi * 2;

      if (y < 1.5) {
        final paint = Paint()
          ..color = piece.color
          ..style = PaintingStyle.fill;

        canvas.save();
        canvas.translate(piece.x * size.width, y * size.height);
        canvas.rotate(rotation);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: piece.size,
              height: piece.size / 2,
            ),
            Radius.circular(piece.size / 4),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConfettiPiece {
  final double x;
  final double y;
  final double speed;
  final Color color;
  final double size;
  final double rotation;

  ConfettiPiece({
    required this.x,
    required this.y,
    required this.speed,
    required this.color,
    required this.size,
    required this.rotation,
  });
}