import 'package:flutter/material.dart';
import 'dart:math';

class AISoundWave extends StatefulWidget {
  final bool isSpeaking;
  const AISoundWave({super.key, required this.isSpeaking});

  @override
  State<AISoundWave> createState() => _AISoundWaveState();
}

class _AISoundWaveState extends State<AISoundWave> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpeaking) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic, color: Colors.blue, size: 40),
      );
    }

    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final randomHeight = 20 + 80 * sin(_controller.value * 2 * pi + index);
              return Container(
                width: 10,
                height: randomHeight.abs(),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}