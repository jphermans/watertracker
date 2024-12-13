import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<double> weeklyData = List.filled(7, 0.0);
  List<double> monthlyData = List.filled(30, 0.0);
  bool _isLoading = true;
  int _dailyTarget = 2000;
  int _totalMonthlyIntake = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _calculatePercentage(int intake, int target) {
    if (target <= 0) return 0.0;
    return (intake / target * 100).clamp(0.0, 100.0);
  }

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    _dailyTarget = prefs.getInt('dailyWaterIntakeTarget') ?? 2000;
    if (_dailyTarget <= 0) _dailyTarget = 2000;
    _totalMonthlyIntake = 0;

    // Load weekly data
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final intake = prefs.getInt('water_$dateKey') ?? 0;
      weeklyData[6 - i] = _calculatePercentage(intake.abs(), _dailyTarget);
    }

    // Load monthly data
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final intake = prefs.getInt('water_$dateKey') ?? 0;
      monthlyData[29 - i] = _calculatePercentage(intake.abs(), _dailyTarget);
      _totalMonthlyIntake += intake.abs();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      // Scroll to the end of the monthly chart after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Widget _buildChart({
    required List<double> data,
    required List<String> labels,
    required double maxX,
    bool isMonthly = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
      child: isMonthly
          ? SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1500,
                child: _buildChartContent(data, labels, maxX, isMonthly, theme),
              ),
            )
          : _buildChartContent(data, labels, maxX, isMonthly, theme),
    );
  }

  Color _getColorForPercentage(double percentage) {
    // Convert percentage to a value between 0 and 1
    final value = percentage / 100;
    
    // Define the colors for the gradient
    const startColor = Colors.red;    // 0%
    const endColor = Colors.green;    // 100%
    
    // Interpolate between the colors based on the value
    return Color.lerp(startColor, endColor, value) ?? startColor;
  }

  Widget _buildChartContent(
    List<double> data,
    List<String> labels,
    double maxX,
    bool isMonthly,
    ThemeData theme,
  ) {
    final spots = data.asMap().entries.map((entry) {
      final value = entry.value.abs().clamp(0.0, 100.0);
      return FlSpot(entry.key.toDouble(), value);
    }).toList();

    final gradientColors = spots.map((spot) => _getColorForPercentage(spot.y)).toList();
    final gradientStops = List<double>.generate(
      spots.length,
      (index) => index / (spots.length - 1),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            checkToShowHorizontalLine: (value) {
              // Only show lines at specific percentages
              return value == 0 || value == 20 || value == 40 || 
                     value == 60 || value == 80 || value == 100;
            },
            getDrawingHorizontalLine: (value) {
              if (value == 0 || value == 100) {
                return FlLine(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  strokeWidth: 1,
                );
              }
              return FlLine(
                color: theme.colorScheme.onSurface.withOpacity(0.15),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              axisNameSize: 30,
              sideTitles: SideTitles(
                showTitles: true,
                interval: isMonthly ? 1 : 1,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (!isMonthly) {
                    final now = DateTime.now();
                    final date = now.subtract(Duration(days: 6 - value.toInt()));
                    final dayName = _getDayName(date.weekday);
                    
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        dayName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    );
                  }
                  
                  final daysAgo = 30 - value.toInt();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      daysAgo.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  String text;
                  if (value == 0) {
                    text = '0%';
                  } else if (value >= 99.9) {
                    text = '100%';
                  } else if (value % 20 == 0) {
                    text = '${value.toInt()}%';
                  } else {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: -0.5,
          maxX: maxX + 0.5,
          minY: -2,
          maxY: 102,
          clipData: FlClipData.none(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              gradient: LinearGradient(
                colors: gradientColors,
                stops: gradientStops,
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final color = _getColorForPercentage(spot.y);
                  return FlDotCirclePainter(
                    radius: 6,
                    color: theme.colorScheme.surface,
                    strokeWidth: 3,
                    strokeColor: color,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(enabled: false),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              'Weekly Overview',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Daily progress as percentage of target',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 20),
                            AspectRatio(
                              aspectRatio: 1.2,
                              child: _buildChart(
                                data: weeklyData,
                                labels: const [],
                                maxX: 6,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Monthly Trend',
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Progress over the last 30 days',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.local_drink,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(_totalMonthlyIntake / 1000).toStringAsFixed(1)}L',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AspectRatio(
                              aspectRatio: 1.2,
                              child: _buildChart(
                                data: monthlyData,
                                labels: const [],
                                maxX: 29,
                                isMonthly: true,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
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
