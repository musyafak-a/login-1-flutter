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
        // Latar belakang gradasi Kuning -> Hijau
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gradYellow,
                AppColors.gradGreen,
              ],
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
