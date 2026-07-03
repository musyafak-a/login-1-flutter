import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GrainyBackground extends StatelessWidget {
  final Widget child;

  const GrainyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Teal
        Container(color: AppColors.gradGreen),
        // Blob Kuning Kanan Atas
        Positioned(
          top: -200,
          right: -150,
          child: Container(
            width: 500,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gradYellow.withValues(alpha: 0.9),
                  AppColors.gradYellow.withValues(alpha: 0.0),
                ],
                stops: const [0.2, 1.0],
              ),
            ),
          ),
        ),
        // Blob Kuning Kiri Bawah
        Positioned(
          bottom: -200,
          left: -150,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gradYellow.withValues(alpha: 0.9),
                  AppColors.gradYellow.withValues(alpha: 0.0),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
        ),
        // Overlay tekstur grain (noise)
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/noise.png'),
              repeat: ImageRepeat.repeat,
              fit: BoxFit.none,
              opacity: 0.25, // Tekstur lebih smooth dan halus
            ),
          ),
        ),
        // Konten utama aplikasi
        child,
      ],
    );
  }
}
