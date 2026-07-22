import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _weeklyStats = [];
  String _lastActivityDate = '-';
  double _totalKm = 0.0;
  double _bestEffortKm = 0.0;
  bool _isLoading = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = AppState.currentUserId ?? 0;
    final weekly = await DatabaseHelper.instance.getWeeklyStats(userId, DateTime.now());
    final allActivities = await DatabaseHelper.instance.getAllActivitiesWithRoute(userId);
    final user = await DatabaseHelper.instance.getUserById(userId);

    double totalKm = 0;
    double bestKm = 0;
    String lastDate = '-';

    if (allActivities.isNotEmpty) {
      final lastAct = DateTime.parse(allActivities.first['date'] as String);
      lastDate = DateFormat('dd MMM yyyy', 'id_ID').format(lastAct);

      for (var a in allActivities) {
        final dist = (a['distanceKm'] as num).toDouble();
        totalKm += dist;
        if (dist > bestKm) {
          bestKm = dist;
        }
      }
    }

    if (mounted) {
      setState(() {
        _currentUser = user;
        _weeklyStats = weekly;
        _totalKm = totalKm;
        _bestEffortKm = bestKm;
        _lastActivityDate = lastDate;
        _isLoading = false;
      });
    }
  }

  void _logout(BuildContext context) {
    AppState.currentUserId = null;
    AppState.currentUserName = null;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.gradYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Foto, Nama, Lokasi, Edit
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                        backgroundImage: _currentUser?.photo != null
                            ? FileImage(File(_currentUser!.photo!))
                            : null,
                        child: _currentUser?.photo == null
                            ? const Icon(Icons.person, color: AppColors.primary, size: 40)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppState.currentUserName ?? 'User',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentUser?.asal?.isNotEmpty == true
                                  ? _currentUser!.asal!
                                  : 'Indonesia', // Lokasi
                              style: const TextStyle(color: Colors.black54, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                          );
                          if (result == true) {
                            _loadData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                          foregroundColor: AppColors.primaryDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Grafik minggu ini
                  _buildWeeklyChartCard(),
                  const SizedBox(height: 24),

                  // Aktivitas (tanggal terakhir)
                  _buildStatRow(Icons.calendar_today, 'Aktivitas Terakhir', _lastActivityDate),
                  const Divider(height: 32, color: Colors.black12),

                  // Statistik (total km)
                  _buildStatRow(Icons.directions_run, 'Total Jarak', '${_totalKm.toStringAsFixed(2)} km'),
                  const Divider(height: 32, color: Colors.black12),

                  // Best effort
                  _buildStatRow(Icons.emoji_events, 'Best Effort', '${_bestEffortKm.toStringAsFixed(2)} km'),
                  const SizedBox(height: 40),
                  
                  // Logout button (dibawah sendiri)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Log out',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
        ),
      ],
    );
  }

  Widget _buildWeeklyChartCard() {
    final maxDistance = _weeklyStats.isEmpty
        ? 1.0
        : _weeklyStats
            .map((e) => e['distanceKm'] as double)
            .fold<double>(0, (a, b) => a > b ? a : b);

    final maxValue = maxDistance == 0 ? 1.0 : maxDistance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Minggu Ini',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyStats.map((d) {
                final date = d['date'] as DateTime;
                final value = d['distanceKm'] as double;
                final heightRatio = maxValue == 0 ? 0.0 : (value / maxValue);
                final isToday = _isSameDay(date, DateTime.now());

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          value == 0 ? '' : value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 90 * heightRatio.clamp(0.03, 1.0),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.primaryLight.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('E', 'id_ID').format(date).substring(0, 2),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? AppColors.primaryDark : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
