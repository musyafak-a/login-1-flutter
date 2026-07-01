import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../database/database_helper.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

enum _RunState { idle, running, paused }

class _RecordScreenState extends State<RecordScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;

  _RunState _state = _RunState.idle;
  final List<LatLng> _routePoints = [];
  LatLng? _currentPosition;
  bool _isLocating = true; // true saat pertama kali mencari lokasi

  double _distanceMeters = 0;
  int _elapsedSeconds = 0;
  String _selectedSport = 'Lari';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  /// Ambil posisi GPS saat halaman pertama kali dibuka,
  /// lalu pusatkan peta ke lokasi nyata perangkat.
  Future<void> _initLocation() async {
    final granted = await _ensurePermission();
    if (!granted) {
      if (mounted) setState(() => _isLocating = false);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        final point = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _currentPosition = point;
          _isLocating = false;
        });
        // Pindahkan peta ke lokasi asli perangkat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(point, 16);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktifkan GPS / Location Service dulu')),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak')),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Izin lokasi ditolak permanen, aktifkan lewat pengaturan HP')),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _start() async {
    final granted = await _ensurePermission();
    if (!granted) return;

    setState(() {
      _state = _RunState.running;
      _routePoints.clear();
      _distanceMeters = 0;
      _elapsedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state == _RunState.running) {
        setState(() => _elapsedSeconds++);
      }
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,   // pakai mode akurasi tinggi (GPS, bukan cuma wifi/cell tower)
      distanceFilter: 3,                 // update posisi tiap pergerakan ≥ 3 meter
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: settings).listen((pos) {
          final newPoint = LatLng(pos.latitude, pos.longitude);

          if (_state == _RunState.running) {
            if (_routePoints.isNotEmpty) {
              final last = _routePoints.last;
              _distanceMeters += Geolocator.distanceBetween(
                last.latitude,
                last.longitude,
                newPoint.latitude,
                newPoint.longitude,
              );
            }
            _routePoints.add(newPoint);
          }

          setState(() => _currentPosition = newPoint);
          _mapController.move(newPoint, _mapController.camera.zoom);
        });
  }

  void _pauseResume() {
    setState(() {
      _state = _state == _RunState.running ? _RunState.paused : _RunState.running;
    });
  }

  Future<void> _stop() async {
    _positionStream?.cancel();
    _timer?.cancel();

    final distanceKm = _distanceMeters / 1000;

    // Minimum jarak untuk disimpan: 2 meter (0.002 km)
    if (distanceKm > 0.002) {
      final userId = AppState.currentUserId ?? 0;
      await DatabaseHelper.instance.insertActivity(
        userId: userId,
        sportType: _selectedSport,
        date: DateTime.now(),
        distanceKm: distanceKm,
        durationSeconds: _elapsedSeconds,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$_selectedSport tersimpan: ${distanceKm.toStringAsFixed(2)} km'),
          ),
        );
      }
    }

    setState(() {
      _state = _RunState.idle;
      _routePoints.clear();
      _distanceMeters = 0;
      _elapsedSeconds = 0;
    });
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

  String _formatPace() {
    final distanceKm = _distanceMeters / 1000;
    if (distanceKm < 0.01 || _elapsedSeconds == 0) return '--:--';
    final paceSecondsPerKm = _elapsedSeconds / distanceKm;
    final m = (paceSecondsPerKm ~/ 60);
    final s = (paceSecondsPerKm % 60).round();
    return '$m\'${s.toString().padLeft(2, '0')}"';
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan posisi perangkat jika sudah didapat, atau fallback ke dunia tengah
    final initialCenter = _currentPosition ?? const LatLng(0, 0);
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_auth_app',
              ),
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppColors.primary,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Overlay loading saat pertama kali mencari lokasi
          if (_isLocating)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Mendapatkan lokasi GPS...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _circleButton(
                    icon: Icons.my_location,
                    onTap: () {
                      if (_currentPosition != null) {
                        _mapController.move(_currentPosition!, 16);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_state == _RunState.idle) _buildSportSelector(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _statColumn('Waktu', _formatTime(_elapsedSeconds)),
                        _statColumn(
                          'Jarak (km)',
                          (_distanceMeters / 1000).toStringAsFixed(2),
                        ),
                        _statColumn('Pace /km', _formatPace()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildControlButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 6),
          ],
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  Widget _buildControlButtons() {
    if (_state == _RunState.idle) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _start,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.fiber_manual_record, color: Colors.white),
          label: const Text(
            'Record',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _pauseResume,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              icon: Icon(
                _state == _RunState.running
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: AppColors.primary,
              ),
              label: Text(
                _state == _RunState.running ? 'Jeda' : 'Lanjut',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _stop,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.stop_rounded, color: Colors.white),
              label: const Text(
                'Selesai',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSportSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Jenis Olahraga:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: DropdownButton<String>(
              value: _selectedSport,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
              underline: const SizedBox(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 14,
              ),
              items: ['Lari', 'Sepeda', 'Jalan']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSport = val);
              },
            ),
          ),
        ],
      ),
    );
  }
}