import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../theme/app_colors.dart';

class StatistikScreen extends StatefulWidget {
  const StatistikScreen({super.key});

  @override
  State<StatistikScreen> createState() => _StatistikScreenState();
}

class _StatistikScreenState extends State<StatistikScreen> {
  List<Map<String, dynamic>> _weeklyStats = [];
  List<Map<String, dynamic>> _monthActivities = [];

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _showDistance = true; // toggle grafik: jarak vs waktu

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final weekly = await DatabaseHelper.instance.getWeeklyStats(DateTime.now());
    final monthly = await DatabaseHelper.instance
        .getActivitiesForMonth(_selectedMonth.year, _selectedMonth.month);
    if (mounted) {
      setState(() {
        _weeklyStats = weekly;
        _monthActivities = monthly;
      });
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i);
      return DateTime(d.year, d.month);
    });

    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: months.map((m) {
              return ListTile(
                title: Text(DateFormat('MMMM yyyy', 'id_ID').format(m)),
                trailing: (m.year == _selectedMonth.year &&
                        m.month == _selectedMonth.month)
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, m),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _selectedMonth = selected);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistik',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pantau perkembangan larimu',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 24),
                _buildWeeklyChartCard(),
                const SizedBox(height: 28),
                _buildMonthlyAttendance(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChartCard() {
    final maxDistance = _weeklyStats.isEmpty
        ? 1.0
        : _weeklyStats
            .map((e) => e['distanceKm'] as double)
            .fold<double>(0, (a, b) => a > b ? a : b);
    final maxDuration = _weeklyStats.isEmpty
        ? 1
        : _weeklyStats
            .map((e) => e['durationSeconds'] as int)
            .fold<int>(0, (a, b) => a > b ? a : b);

    final maxValue = _showDistance
        ? (maxDistance == 0 ? 1.0 : maxDistance)
        : (maxDuration == 0 ? 1 : maxDuration).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Minggu Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              _toggleChip(),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyStats.map((d) {
                final date = d['date'] as DateTime;
                final value = _showDistance
                    ? d['distanceKm'] as double
                    : (d['durationSeconds'] as int).toDouble();
                final heightRatio = maxValue == 0 ? 0.0 : (value / maxValue);
                final isToday = _isSameDay(date, DateTime.now());

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          value == 0
                              ? ''
                              : (_showDistance
                                  ? value.toStringAsFixed(1)
                                  : '${(value / 60).round()}m'),
                          style: const TextStyle(fontSize: 9, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 90 * heightRatio.clamp(0.03, 1.0),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('E', 'id_ID').format(date).substring(0, 2),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? AppColors.primary : Colors.black54,
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

  Widget _toggleChip() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chipOption('Jarak', _showDistance, () {
            setState(() => _showDistance = true);
          }),
          _chipOption('Waktu', !_showDistance, () {
            setState(() => _showDistance = false);
          }),
        ],
      ),
    );
  }

  Widget _chipOption(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyAttendance() {
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday; // 1=Mon

    // hitung intensitas per tanggal (jumlah aktivitas hari itu)
    final Map<int, int> intensityByDay = {};
    for (final a in _monthActivities) {
      final d = DateTime.parse(a['date'] as String);
      intensityByDay[d.day] = (intensityByDay[d.day] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tabel Absen',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              GestureDetector(
                onTap: _pickMonth,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('MMM yyyy', 'id_ID').format(_selectedMonth),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarGrid(daysInMonth, firstWeekday, intensityByDay),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
    int daysInMonth,
    int firstWeekday,
    Map<int, int> intensityByDay,
  ) {
    final leadingEmpty = firstWeekday - 1; // Senin = kolom pertama
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        const Row(
          children: [
            _DayLabel('S'),
            _DayLabel('S'),
            _DayLabel('R'),
            _DayLabel('K'),
            _DayLabel('J'),
            _DayLabel('S'),
            _DayLabel('M'),
          ],
        ),
        const SizedBox(height: 6),
        for (int row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNumber = cellIndex - leadingEmpty + 1;
                final isValidDay = dayNumber >= 1 && dayNumber <= daysInMonth;
                final intensity =
                    isValidDay ? (intensityByDay[dayNumber] ?? 0) : 0;

                return Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !isValidDay
                            ? Colors.transparent
                            : _intensityColor(intensity),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isValidDay
                          ? Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 9,
                                color: intensity > 0
                                    ? Colors.white
                                    : Colors.black45,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Color _intensityColor(int intensity) {
    if (intensity <= 0) return Colors.grey.shade100;
    if (intensity == 1) return AppColors.primary.withOpacity(0.3);
    if (intensity == 2) return AppColors.primary.withOpacity(0.6);
    if (intensity == 3) return AppColors.primary.withOpacity(0.85);
    return AppColors.primaryDark;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Less', style: TextStyle(fontSize: 10, color: Colors.black45)),
        const SizedBox(width: 6),
        _legendBox(Colors.grey.shade100),
        _legendBox(AppColors.primary.withOpacity(0.3)),
        _legendBox(AppColors.primary.withOpacity(0.6)),
        _legendBox(AppColors.primary.withOpacity(0.85)),
        _legendBox(AppColors.primaryDark),
        const SizedBox(width: 6),
        const Text('More', style: TextStyle(fontSize: 10, color: Colors.black45)),
      ],
    );
  }

  Widget _legendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayLabel extends StatelessWidget {
  final String label;
  const _DayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black45),
        ),
      ),
    );
  }
}
