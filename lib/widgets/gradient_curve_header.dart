import 'package:flutter/material.dart';

/// Header dengan gradient ungu melengkung di pojok kanan atas,
/// meniru desain pada referensi (curve besar di kanan).
class GradientCurveHeader extends StatelessWidget {
  final double height;
  final bool showBackButton;
  final VoidCallback? onBack;

  const GradientCurveHeader({
    super.key,
    this.height = 300,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          // Curve gradient shape di kanan atas
          Positioned(
            top: -height * 0.35,
            right: -60,
            child: Container(
              width: 320,
              height: height * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    const Color(0xFFC4A6F5).withOpacity(0.9),
                    const Color(0xFFEDE3FB).withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          if (showBackButton)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.black87, size: 20),
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
