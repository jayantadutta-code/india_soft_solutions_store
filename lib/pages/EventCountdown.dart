import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';


class EventCountdown extends StatefulWidget {
  const EventCountdown({super.key});

  @override
  State<EventCountdown> createState() => _EventCountdownState();
}

class _EventCountdownState extends State<EventCountdown> with TickerProviderStateMixin {
  String? eventName;
  DateTime? eventDateTime;

  int days = 0;
  int hours = 0;
  int minutes = 0;
  int seconds = 0;
  double progress = 0.0;

  Timer? _timer;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  DateTime? _pickedDate;
  TimeOfDay? _pickedTime;
  bool _isEventActive = false;

  // Colors for gradient
  final List<Color> _gradientColors = [
    const Color(0xFF6C63FF),
    const Color(0xFFFF6584),
    const Color(0xFFFFD166),
    const Color(0xFF06D6A0),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Load saved event when app starts
    _loadSavedEvent();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _glowController.dispose();
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // Save event to shared preferences
  Future<void> _saveEvent() async {
    if (eventName == null || eventDateTime == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('eventName', eventName!);
    await prefs.setString('eventDateTime', eventDateTime!.toIso8601String());
  }

  // Load event from shared preferences
  Future<void> _loadSavedEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('eventName');
    final savedDateTime = prefs.getString('eventDateTime');

    if (savedName != null && savedDateTime != null) {
      setState(() {
        eventName = savedName;
        eventDateTime = DateTime.parse(savedDateTime);
      });

      // Start countdown with saved event
      Future.delayed(const Duration(milliseconds: 100), () {
        startCountdown();
      });
    }
  }

  // Clear saved event
  Future<void> _clearSavedEvent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('eventName');
    await prefs.remove('eventDateTime');
  }

  void startCountdown() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (eventDateTime == null) return;

      final now = DateTime.now();
      final diff = eventDateTime!.difference(now);

      if (diff.isNegative) {
        timer.cancel();
        setState(() {
          _isEventActive = false;
        });
        return;
      }

      setState(() {
        days = diff.inDays;
        hours = diff.inHours % 24;
        minutes = diff.inMinutes % 60;
        seconds = diff.inSeconds % 60;
        _isEventActive = true;

        // Calculate progress (simplified)
        if (days < 365) {
          progress = 1 - (days / 365);
        } else {
          progress = 0.0;
        }
      });
    });
  }

  void _resetEvent() {
    setState(() {
      eventName = null;
      eventDateTime = null;
      _isEventActive = false;
      _nameController.clear();
      _dateController.clear();
      _timeController.clear();
      _pickedDate = null;
      _pickedTime = null;
      progress = 0.0;
    });
    _timer?.cancel();
    _clearSavedEvent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: const Row(
                children: [
                  Icon(Icons.timer, size: 24),
                  SizedBox(width: 10),
                  Text('Event Countdown', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        actions: eventName != null ? [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetEvent,
            tooltip: 'Reset Event',
          ),
        ] : null,
      ),

      body: Stack(
        children: [
          // Animated background gradient
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.5 + (_glowAnimation.value * 0.2),
                      colors: [
                        const Color(0xFF6C63FF).withAlpha(20),
                        const Color(0xFFFF6584).withAlpha(10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          Center(
            child: eventName == null
                ? _buildEmptyState()
                : _buildCountdownDisplay(),
          ),
        ],
      ),

      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, sin(_pulseController.value * 2 * pi) * 10),
                  child: Icon(
                    Icons.event_note,
                    size: 120,
                    color: const Color(0xFF6C63FF).withAlpha(150),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              'No Event Added Yet',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the + button below to create your first event countdown',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            _buildFeatureGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {'icon': Icons.notifications_active, 'title': 'Real-time\nCountdown'},
      {'icon': Icons.celebration, 'title': 'Visual\nProgress'},
      {'icon': Icons.palette, 'title': 'Beautiful\nAnimations'},
      {'icon': Icons.save, 'title': 'Auto-save\nData'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.9 + (0.1 * sin(_pulseController.value * 2 * pi + index * 0.5)),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _gradientColors[index % _gradientColors.length].withAlpha(50),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      features[index]['icon'] as IconData,
                      size: 40,
                      color: _gradientColors[index % _gradientColors.length],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      features[index]['title'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCountdownDisplay() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Event Name
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6C63FF),
                          const Color(0xFFFF6584),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6584).withAlpha(80),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      eventName!,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // Countdown Timer
            _buildTimerDisplay(),

            const SizedBox(height: 40),

            // Progress Bar
            _buildProgressBar(),

            const SizedBox(height: 20),

            // Event Date Info
            if (eventDateTime != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Event Date & Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatDateTime(eventDateTime!),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6C63FF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    if (_isEventActive) ...[
                      const Divider(),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Auto-saved',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Reset Button
            if (_isEventActive)
              ElevatedButton.icon(
                onPressed: _resetEvent,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF6584),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Column(
      children: [
        Text(
          'Time Remaining',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 20),

        // Timer Display with responsive layout
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
          children: [
            _TimeUnit(value: days, label: 'DAYS', color: const Color(0xFF6C63FF)),
            _TimeUnit(value: hours, label: 'HOURS', color: const Color(0xFFFF6584)),
            _TimeUnit(value: minutes, label: 'MINUTES', color: const Color(0xFFFFD166)),
            _TimeUnit(value: seconds, label: 'SECONDS', color: const Color(0xFF06D6A0)),
          ],
        ),

        const SizedBox(height: 20),

        // Compact timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            '$days days $hours hrs $minutes min $seconds sec',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 12,
                width: MediaQuery.of(context).size.width * 0.8 * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF),
                      const Color(0xFFFF6584),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withAlpha(100),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: _openEventSheet,
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.add),
            label: Text(eventName == null ? 'Add Event' : 'Edit Event'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        );
      },
    );
  }

  void _openEventSheet() {
    // Pre-fill if editing
    if (eventName != null) {
      _nameController.text = eventName!;
      if (eventDateTime != null) {
        _pickedDate = eventDateTime;
        _dateController.text = '${eventDateTime!.day}/${eventDateTime!.month}/${eventDateTime!.year}';
        _pickedTime = TimeOfDay.fromDateTime(eventDateTime!);
        _timeController.text = '${_pickedTime!.hour}:${_pickedTime!.minute.toString().padLeft(2, '0')}';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),

                    Text(
                      eventName == null ? 'Create New Event' : 'Edit Event',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          _buildInputField(
                            controller: _nameController,
                            label: 'Event Name',
                            hint: 'Enter event name',
                            icon: Icons.event,
                          ),

                          const SizedBox(height: 15),

                          _buildDateField(
                            controller: _dateController,
                            label: 'Event Date',
                            onTap: _selectDate,
                          ),

                          const SizedBox(height: 15),

                          _buildDateField(
                            controller: _timeController,
                            label: 'Event Time',
                            onTap: _selectTime,
                            icon: Icons.access_time,
                          ),

                          const SizedBox(height: 30),

                          if (_pickedDate != null && _pickedTime != null) ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withAlpha(10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF6C63FF).withAlpha(50),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Selected Date & Time',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6C63FF),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${_dateController.text} at ${_timeController.text}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_pickedDate == null || _pickedTime == null || _nameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                                backgroundColor: Color(0xFFFF6584),
                              ),
                            );
                            return;
                          }

                          eventDateTime = DateTime(
                            _pickedDate!.year,
                            _pickedDate!.month,
                            _pickedDate!.day,
                            _pickedTime!.hour,
                            _pickedTime!.minute,
                          );

                          setState(() {
                            eventName = _nameController.text;
                          });

                          // Save to shared preferences
                          await _saveEvent();

                          startCountdown();
                          Navigator.pop(context);

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Event saved successfully!'),
                              backgroundColor: Colors.green[600],
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Save Event',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),

                    if (eventName != null) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _resetEvent,
                        child: const Text(
                          'Clear Event',
                          style: TextStyle(color: Color(0xFFFF6584)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  icon ?? Icons.calendar_today,
                  color: const Color(0xFF6C63FF),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'Select $label' : controller.text,
                    style: TextStyle(
                      color: controller.text.isEmpty ? Colors.grey[400] : Colors.grey[800],
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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

    if (picked != null) {
      _pickedDate = picked;
      _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _pickedTime ?? TimeOfDay.now(),
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

    if (picked != null) {
      _pickedTime = picked;
      _timeController.text = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return '${daysOfWeek[dateTime.weekday - 1]}, ${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _TimeUnit({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(50), width: 2),
            ),
            child: Center(
              child: Text(
                value.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}