import 'dart:io';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'home_screen.dart';
import 'record_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'statistik_screen.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/light_grainy_background.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  String? _photoPath;

  final List<Widget> _pages = const [
    HomeScreen(),
    RecordScreen(),
    HistoryScreen(),
    StatistikScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    AppState.refreshNotifier.addListener(_loadUser);
  }

  @override
  void dispose() {
    AppState.refreshNotifier.removeListener(_loadUser);
    super.dispose();
  }

  Future<void> _loadUser() async {
    final userId = AppState.currentUserId;
    if (userId != null) {
      final user = await DatabaseHelper.instance.getUserById(userId);
      if (mounted) {
        setState(() {
          _photoPath = user?.photo;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LightGrainyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        extendBody: true, // Membuat konten utama memanjang hingga ke bawah navigasi
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_currentIndex == 1) return null; // No appbar on RecordScreen
    return AppBar(
      backgroundColor: AppColors.gradYellow,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 70, // Beri ruang sedikit lebih lega
      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
              backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
              child: _photoPath == null ? const Icon(Icons.person, color: AppColors.primary) : null,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppState.currentUserName ?? 'User',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const Text(
                'Siap lari hari ini?',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
