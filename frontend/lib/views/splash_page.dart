import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kloudshop/app.dart'; // for AuthGate

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  double _opacity = 0.0;
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();

    // Loop controller running the continuous scale and spin animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Pulsing animation: grows and shrinks seamlessly between 0.85x and 1.15x
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.15).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.85).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Rotation animation: rotates 360 degrees (2*pi) continuously
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    // Start repeating the loop continuously
    _controller.repeat();

    // Trigger the initial fade-in exactly once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

    // Hold the splash screen for exactly 3.0 seconds (matching the 360-degree rotation cycle)
    // then transition using pushReplacement to completely remove SplashPage and trigger dispose.
    _transitionTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        final isPreview = Uri.base.toString().contains('/preview') ||
            (ModalRoute.of(context)?.settings.name?.contains('/preview') ?? false);
        final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;

        if (!isPreview && isCurrent) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const AuthGate(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent it from firing after the widget is disposed
    _transitionTimer?.cancel();
    // Stop and dispose the animation controller to release ticker resources
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeIn,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Image.asset(
              'assets/logo3d.png',
              width: 300,
              height: 300,
            ),
          ),
        ),
      ),
    );
  }
}
