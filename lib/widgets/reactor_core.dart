import 'dart:math' as math;
import 'package:flutter/material.dart';

class ReactorCore extends StatefulWidget {
  const ReactorCore({super.key, this.active = false});

  final bool active;

  @override
  State<ReactorCore> createState() => _ReactorCoreState();
}

class _ReactorCoreState extends State<ReactorCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
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
      builder: (context, _) {
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BFFF)
                          .withOpacity(widget.active ? 0.55 : 0.28),
                      blurRadius: widget.active ? 48 : 30,
                      spreadRadius: 8,
                    ),
                  ],
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFB9F7FF),
                      Color(0xFF087CCB),
                      Color(0xFF03142C),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.bolt,
                  color: Colors.white,
                  size: 58,
                ),
              ),
              Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: Container(
                  width: 205,
                  height: 205,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF20DFFF),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Transform.rotate(
                angle: -_controller.value * 2 * math.pi,
                child: Container(
                  width: 178,
                  height: 178,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF58AFFF),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
