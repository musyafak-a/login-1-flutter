import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
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
    final distanceKm = activity['distanceKm'] as double;
    final durationSeconds = activity['durationSeconds'] as int;
    final pace = activity['paceSecondsPerKm'] as double;
    final sportType = activity['sportType'] as String;
    final date = DateTime.parse(activity['date'] as String);

    final screenshotController = ScreenshotController();

    // Estimasi elevasi (0 karena tidak ada data GPS elevation)
    const int elevationGain = 0;
    const int maxElevation = 90;

    final userName = AppState.currentUserName ?? 'Pengguna';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    // Format tanggal mirip Strava: "01 Juli 2026 pu13ul 13.49"
    final dateStr = DateFormat("dd MMMM yyyy • HH.mm", 'id_ID').format(date);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // ─── Konten Detail (scrollable) ───
              CustomScrollView(
                slivers: [
                  // Peta di atas
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: routePoints.isEmpty
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
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.flutter_auth_app',
                                ),
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: routePoints,
                                      color: Colors.deepOrange,
                                      strokeWidth: 5,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),

                  // ─── Info Body ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User info row
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.deepPurple,
                                child: Text(
                                  userInitial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.directions_run,
                                            size: 13, color: Colors.black54),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '$dateStr · Kediri, East...',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
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

                          const SizedBox(height: 20),

                          // Judul aktivitas
                          Text(
                            '$sportType Pagi',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Divider(color: Colors.black12),
                          const SizedBox(height: 12),

                          // Stats Grid — 2 kolom
                          Row(
                            children: [
                              Expanded(
                                child: _detailStatItem(
                                  'Jarak',
                                  '${distanceKm.toStringAsFixed(2)} km',
                                ),
                              ),
                              Expanded(
                                child: _detailStatItem(
                                  'Pace Rata2',
                                  '${_formatPace(pace)} /km',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: _detailStatItem(
                                  'Waktu Bergerak',
                                  _formatTime(durationSeconds),
                                ),
                              ),
                              Expanded(
                                child: _detailStatItem(
                                  'Kenaikan Elevasi',
                                  '$elevationGain m',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          _detailStatItem('Elevasi Maks', '$maxElevation m'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ─── Tombol Overlay (back, download, more) ───
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
                          _actionButton(
                            icon: Icons.download_rounded,
                            onTap: () async {
                              // Screenshot dalam tampilan bergaya gelap (Strava-like)
                              await _captureAndSave(
                                context,
                                screenshotController,
                                routePoints,
                                sportType,
                                distanceKm,
                                durationSeconds,
                                pace,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _actionButton(
                            icon: Icons.more_vert_rounded,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) {
                                  return SafeArea(
                                    child: Wrap(
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.delete_outline,
                                              color: Colors.red),
                                          title: const Text('Hapus Aktivitas',
                                              style: TextStyle(color: Colors.red)),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            await DatabaseHelper.instance
                                                .deleteActivity(activity['id']);
                                            if (mounted) {
                                              AppState.refreshNotifier.value++;
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Aktivitas berhasil dihapus')),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Screenshot controller (tidak terlihat, untuk download)
              Offstage(
                child: Screenshot(
                  controller: screenshotController,
                  child: Container(width: 1, height: 1, color: Colors.transparent),
                ),
              ),
            ],
          ),
        );
      },
    ));
  }

  /// Tampilkan overlay screenshot bergaya gelap, capture, lalu simpan ke galeri
  Future<void> _captureAndSave(
    BuildContext context,
    ScreenshotController screenshotController,
    List<LatLng> routePoints,
    String sportType,
    double distanceKm,
    int durationSeconds,
    double pace,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Buat widget screenshot secara off-screen
      final sc = ScreenshotController();
      final bytes = await sc.captureFromLongWidget(
        _buildDownloadWidget(
          routePoints: routePoints,
          sportType: sportType,
          distanceKm: distanceKm,
          durationSeconds: durationSeconds,
          pace: pace,
        ),
        delay: const Duration(milliseconds: 300),
      );
      await Gal.putImageBytes(bytes);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Aktivitas berhasil diunduh ke Galeri')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal mengunduh: $e')),
        );
      }
    }
  }

  /// Widget bergaya Strava gelap — khusus untuk di-screenshot dan disimpan
  Widget _buildDownloadWidget({
    required List<LatLng> routePoints,
    required String sportType,
    required double distanceKm,
    required int durationSeconds,
    required double pace,
  }) {
    return SizedBox(
      width: 390,
      height: 844,
      child: Stack(
        children: [
          // Map Background
          Positioned.fill(
            child: routePoints.isEmpty
                ? Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                        child: Icon(Icons.map, color: Colors.grey, size: 60)),
                  )
                : FlutterMap(
                    options: MapOptions(
                      initialCameraFit: CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(routePoints),
                        padding: const EdgeInsets.all(60),
                      ),
                      interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.flutter_auth_app',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: Colors.deepOrange,
                            strokeWidth: 6,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          // Gradient + Stats Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.directions_run_rounded,
                          color: Colors.white, size: 36),
                      Text(
                        'LATIHAN',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$sportType Pagi',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _stravaStatItem(
                              'Pace', '${_formatPace(pace)} /km')),
                      Expanded(
                          child: _stravaStatItem(
                        'Waktu',
                        durationSeconds >= 3600
                            ? '${durationSeconds ~/ 3600}j ${(durationSeconds % 3600) ~/ 60}m'
                            : '${durationSeconds ~/ 60}m ${durationSeconds % 60}d',
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _stravaStatItem('Jarak',
                      '${distanceKm.toStringAsFixed(2)} km',
                      isLarge: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _stravaStatItem(String label, String value, {bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 32 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Stat item untuk tampilan detail putih (mirip Strava light mode)
  Widget _detailStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 4),
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
