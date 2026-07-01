import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    AppState.refreshNotifier.addListener(_loadHistory);
  }

  @override
  void dispose() {
    AppState.refreshNotifier.removeListener(_loadHistory);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final userId = AppState.currentUserId ?? 0;
    final data = await DatabaseHelper.instance.getAllActivitiesWithRoute(userId);
    if (mounted) {
      setState(() {
        _activities = data;
        _isLoading = false;
      });
    }
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$mm:$ss';
    return '$mm:$ss';
  }

  String _formatPace(double paceSecondsPerKm) {
    if (paceSecondsPerKm == 0) return '--:--';
    final m = (paceSecondsPerKm ~/ 60);
    final s = (paceSecondsPerKm % 60).round();
    return '$m\'${s.toString().padLeft(2, '0')}"';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Riwayat Latihan',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _activities.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada riwayat',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: _activities.length,
                          itemBuilder: (context, index) {
                            final activity = _activities[index];
                            return _buildHistoryCard(activity);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> activity) {
    final date = DateTime.parse(activity['date'] as String);
    final distanceKm = activity['distanceKm'] as double;
    final durationSeconds = activity['durationSeconds'] as int;
    final pace = activity['paceSecondsPerKm'] as double;
    final sportType = activity['sportType'] as String;
    final routeStr = activity['route'] as String;
    
    List<LatLng> routePoints = [];
    try {
      final List<dynamic> parsed = jsonDecode(routeStr);
      routePoints = parsed.map((e) => LatLng(e['lat'] as double, e['lng'] as double)).toList();
    } catch (_) {}

    return GestureDetector(
      onTap: () => _showHistoryDetail(activity, routePoints),
      child: Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Peta Statis
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: routePoints.isEmpty
                  ? Container(
                      color: Colors.grey.shade100,
                      child: const Center(child: Icon(Icons.map, color: Colors.grey, size: 40)),
                    )
                  : FlutterMap(
                      options: MapOptions(
                        initialCameraFit: CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(routePoints),
                          padding: const EdgeInsets.all(20),
                        ),
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.flutter_auth_app',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              color: AppColors.primary,
                              strokeWidth: 4,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          
          // Informasi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sportType,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date),
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statItem('Jarak', '${distanceKm.toStringAsFixed(2)} km'),
                    _statItem('Waktu', _formatTime(durationSeconds)),
                    _statItem('Pace', '${_formatPace(pace)} /km'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showHistoryDetail(Map<String, dynamic> activity, List<LatLng> routePoints) {
    final date = DateTime.parse(activity['date'] as String);
    final distanceKm = activity['distanceKm'] as double;
    final durationSeconds = activity['durationSeconds'] as int;
    final pace = activity['paceSecondsPerKm'] as double;
    final sportType = activity['sportType'] as String;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Top half: Map
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    routePoints.isEmpty
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.map, color: Colors.grey, size: 60),
                            ),
                          )
                        : FlutterMap(
                            options: MapOptions(
                              initialCameraFit: CameraFit.bounds(
                                bounds: LatLngBounds.fromPoints(routePoints),
                                padding: const EdgeInsets.all(40),
                              ),
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.flutter_auth_app',
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: routePoints,
                                    color: Colors.deepOrange, // Matches Strava orange
                                    strokeWidth: 6,
                                  ),
                                ],
                              ),
                            ],
                          ),
                    // Back button & icons
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _actionButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            Row(
                              children: [
                                _actionButton(icon: Icons.bookmark_border_rounded, onTap: () {}),
                                const SizedBox(width: 12),
                                _actionButton(
                                  icon: Icons.more_vert_rounded, 
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      builder: (context) {
                                        return SafeArea(
                                          child: Wrap(
                                            children: [
                                              ListTile(
                                                leading: const Icon(Icons.delete_outline, color: Colors.red),
                                                title: const Text('Hapus Aktivitas', style: TextStyle(color: Colors.red)),
                                                onTap: () async {
                                                  // Tutup bottom sheet
                                                  Navigator.pop(context);
                                                  
                                                  // Hapus dari database
                                                  await DatabaseHelper.instance.deleteActivity(activity['id']);
                                                  
                                                  // Refresh history state globally
                                                  if (mounted) {
                                                    AppState.refreshNotifier.value++;
                                                    // Tutup halaman detail
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Aktivitas berhasil dihapus')),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom half: Details
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Profile Row
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.purple.shade400,
                              radius: 24,
                              child: const Text('M', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Muhammad Yusril musyafak',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_run_rounded, size: 16, color: Colors.black54),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${DateFormat('dd MMMM yyyy pukul HH.mm', 'id_ID').format(date)} · Kediri, East Java',
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Title
                        Text(
                          '$sportType Pagi',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Stats Grid
                        Row(
                          children: [
                            Expanded(child: _detailStatItem('Jarak', '${distanceKm.toStringAsFixed(2)} km')),
                            Expanded(child: _detailStatItem('Pace Rata2', '${_formatPace(pace)} /km')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _detailStatItem('Waktu Bergerak', _formatTime(durationSeconds))),
                            Expanded(child: _detailStatItem('Kenaikan Elevasi', '0 m')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _detailStatItem('Elevasi Maks', '90 m')),
                            Expanded(child: const SizedBox()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ));
  }

  Widget _actionButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }

  Widget _detailStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
