import 'dart:async';
import 'package:flutter/material.dart';

class SnackbarCountdown extends StatefulWidget {
  final String message;
  final int durationSeconds;

  const SnackbarCountdown({
    super.key,
    required this.message,
    this.durationSeconds = 3,
  });

  @override
  State<SnackbarCountdown> createState() => _SnackbarCountdownState();
}

class _SnackbarCountdownState extends State<SnackbarCountdown> {
  late int _timeLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.durationSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) {
          setState(() {
            _timeLeft--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(widget.message)),
        Text(
          '($_timeLeft)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
