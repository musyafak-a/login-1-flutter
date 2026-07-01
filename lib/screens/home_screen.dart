import 'package:flutter/material.dart';
import '../widgets/gradient_curve_header.dart';
import '../theme/app_colors.dart';

import '../database/database_helper.dart';
import '../state/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _todayCount = 0;
  int _streak = 0;
  String _favorite = 'Lari';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOverview();
    AppState.refreshNotifier.addListener(_loadOverview);
  }

  @override
  void dispose() {
    AppState.refreshNotifier.removeListener(_loadOverview);
    super.dispose();
  }

  Future<void> _loadOverview() async {
    final userId = AppState.currentUserId ?? 0;
    final overview = await DatabaseHelper.instance.getUserOverview(userId);
    if (mounted) {
      setState(() {
        _todayCount = overview['todayCount'] as int;
        _streak = overview['streak'] as int;
        _favorite = overview['favorite'] as String;
        _isLoading = false;
      });
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const GradientCurveHeader(height: 260),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome 👋',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selamat datang kembali, siap lari hari ini?',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildOverviewCard(),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Log out',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildOverviewItem(
            icon: Icons.directions_run_rounded,
            value: _todayCount.toString(),
            label: 'Aktivitas\nHari Ini',
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.black12,
          ),
          _buildOverviewItem(
            icon: Icons.local_fire_department_rounded,
            value: '$_streak Hari',
            label: 'Streak\nOlahraga',
            iconColor: Colors.orange,
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.black12,
          ),
          _buildOverviewItem(
            icon: Icons.favorite_rounded,
            value: _favorite,
            label: 'Olahraga\nFavorit',
            iconColor: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem({
    required IconData icon,
    required String value,
    required String label,
    Color iconColor = AppColors.primary,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
