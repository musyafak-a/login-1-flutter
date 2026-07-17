import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LightGrainyBackground extends StatelessWidget {
  final Widget child;

  const LightGrainyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base White
        Container(color: Colors.white),
        // Gradient Hijau tipis di kanan atas
        Positioned(
          top: -150,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gradGreen.withValues(alpha: 0.3),
                  AppColors.gradGreen.withValues(alpha: 0.0),
                ],
                stops: const [0.2, 1.0],
              ),
            ),
          ),
        ),
        // Gradient Kuning tipis di kiri bawah
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gradYellow.withValues(alpha: 0.3),
                  AppColors.gradYellow.withValues(alpha: 0.0),
                ],
                stops: const [0.2, 1.0],
              ),
            ),
          ),
        ),
        // Texture grain (noise)
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/noise.png'),
              repeat: ImageRepeat.repeat,
              fit: BoxFit.none,
              opacity: 0.25,
            ),
          ),
        ),
        // Main content
        child,
      ],
    );
  }
}
