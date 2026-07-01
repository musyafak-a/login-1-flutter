import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background putih untuk bottom nav
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          top: 20,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, -2),
                )
              ],
            ),
          ),
        ),
        
        // Lingkaran oren yang bergeser secara smooth (berada di belakang icon)
        SafeArea(
          top: false,
          child: SizedBox(
            height: 75,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 4;
                final circleSize = 56.0;
                final leftPosition = (tabWidth * currentIndex) + (tabWidth - circleSize) / 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      top: 4, // Y center = 32
                      left: leftPosition,
                      child: Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Row untuk Icon dan Text yang bisa di-klik
        SafeArea(
          top: false,
          child: SizedBox(
            height: 75,
            child: Row(
              children: [
                _navItem(Icons.home_rounded, 'Home', 0),
                _navItem(Icons.directions_run_rounded, 'Record', 1),
                _navItem(Icons.history_rounded, 'History', 2),
                _navItem(Icons.bar_chart_rounded, 'Statistik', 3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final bool isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: SizedBox(
          height: 75,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Icon yang bergerak naik/turun dan berubah warna
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                top: isActive ? 18 : 30, // Naik ke tengah lingkaran jika aktif. Turun ke 32 jika tidak aktif (lebih tinggi agar jarak ke teks lebih lebar)
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: isActive ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) {
                    final color = Color.lerp(Colors.grey.shade400, Colors.white, t);
                    final size = 26.0 + (2.0 * t); // membesar sedikit dari 26 ke 28
                    return Icon(icon, color: color, size: size);
                  },
                ),
              ),
              // Teks yang memudar dan bergeser turun jika aktif
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                bottom: isActive ? -10 : 8, // Turun sedikit ke 8 agar jarak dari ikon makin lebar
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: isActive ? 0.0 : 1.0,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
