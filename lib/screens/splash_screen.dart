import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Berpindah ke halaman login setelah 2.5 detik
    Timer(const Duration(milliseconds: 2500), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
          // Logo aplikasi di tengah
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0), // sedikit border radius
              child: Image.asset(
                'assets/images/logo.png',
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
