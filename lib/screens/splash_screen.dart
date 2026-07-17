import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/grainy_background.dart';

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
    return GrainyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
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
      ),
    );
  }
}
