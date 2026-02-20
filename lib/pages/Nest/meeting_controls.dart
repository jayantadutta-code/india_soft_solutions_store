import 'package:flutter/material.dart';

class MeetingControls extends StatelessWidget {
  final VoidCallback onToggleMicButtonPressed;
  final VoidCallback onToggleCameraButtonPressed;
  final VoidCallback onLeaveButtonPressed;
  final bool micEnabled;
  final bool camEnabled;

  const MeetingControls({
    super.key,
    required this.onToggleMicButtonPressed,
    required this.onToggleCameraButtonPressed,
    required this.onLeaveButtonPressed,
    required this.micEnabled,
    required this.camEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mic Button
          _buildControlButton(
            icon: micEnabled ? Icons.mic : Icons.mic_off,
            label: micEnabled ? 'Mute' : 'Unmute',
            color: micEnabled ? Colors.blue : Colors.grey,
            onPressed: onToggleMicButtonPressed,
            backgroundColor: micEnabled ? Colors.blue.shade50 : Colors.grey.shade100,
          ),

          // Camera Button
          _buildControlButton(
            icon: camEnabled ? Icons.videocam : Icons.videocam_off,
            label: camEnabled ? 'Stop' : 'Start',
            color: camEnabled ? Colors.blue : Colors.grey,
            onPressed: onToggleCameraButtonPressed,
            backgroundColor: camEnabled ? Colors.blue.shade50 : Colors.grey.shade100,
          ),

          // Leave Button
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            color: Colors.red,
            onPressed: onLeaveButtonPressed,
            backgroundColor: Colors.red.shade50,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
              backgroundColor: backgroundColor,
              foregroundColor: color,
              elevation: 4,
              shadowColor: color.withOpacity(0.3),
            ),
            child: Icon(icon, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}