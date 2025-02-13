import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/setup_screen.dart';
import 'screens/statistics_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tapped logic here
      },
    );
  }

  Future<void> _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
    });
  }

  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeMode.index);
  }

  void _handleThemeModeChanged(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
    _saveThemeMode(themeMode);
  }

  /// Builds the MaterialApp for the Water Tracker application, configuring the theme, theme mode, and home screen.
  ///
  /// The `build` method returns a `MaterialApp` widget that sets the application's title, theme, dark theme, and theme mode. It also sets the home screen to the `MainScreen` widget, passing the `_handleThemeModeChanged` callback to allow the home screen to update the theme mode.
  /// Builds the MaterialApp for the Water Tracker application, configuring the theme, theme mode, and home screen.
  ///
  /// The `build` method returns a `MaterialApp` widget that sets the application's title, theme, dark theme, and theme mode. It also sets the home screen to the `MainScreen` widget, passing the `_handleThemeModeChanged` callback to allow the home screen to update the theme mode.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BCD4),
          primary: const Color(0xFF00BCD4),
          secondary: const Color(0xFF03A9F4),
        ),
        brightness: Brightness.light,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BCD4),
          brightness: Brightness.dark,
          primary: const Color(0xFF00BCD4),
          secondary: const Color(0xFF03A9F4),
        ),
        brightness: Brightness.dark,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: MainScreen(onThemeModeChanged: _handleThemeModeChanged),
    );
  }
}

class _WaterProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;

  _WaterProgressPainter({
    required this.progress,
    required this.backgroundColor,
  });

  Color _getColorForProgress(double progress) {
    // Define the colors for the gradient
    const startColor = Colors.red; // 0%
    const endColor = Colors.green; // 100%

    // Interpolate between the colors based on the progress
    return Color.lerp(startColor, endColor, progress) ?? startColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.1;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Draw progress arc with color based on progress
    final progressPaint = Paint()
      ..color = _getColorForProgress(progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -90 * (3.14159 / 180), // Start from top (-90 degrees)
      progress * 2 * 3.14159, // Convert progress to radians
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_WaterProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _WaterButton extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;

  const _WaterButton({
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.water_drop,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                '+$amount ml',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const MainScreen({super.key, required this.onThemeModeChanged});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _dailyWaterIntake = 0;
  int _dailyWaterIntakeTarget = 2000;
  late AnimationController _controller;
  late Animation<double> _animation;
  int _selectedIndex = 0;
  DateTime _lastDrinkTime = DateTime.now();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadWaterIntakeData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    _startHourlyCheck();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tapped logic here
      },
    );
  }

  void _startHourlyCheck() {
    Timer.periodic(const Duration(hours: 1), (timer) {
      if (DateTime.now().difference(_lastDrinkTime).inHours >= 1) {
        _showNotification();
      }
    });
  }

  Future<void> _loadWaterIntakeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get the current date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final lastUsedDate = prefs.getInt('lastUsedDate') ?? today;

    // Check if it's a new day
    if (today > lastUsedDate) {
      // Save yesterday's data before resetting
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey =
          '${yesterday.year}-${yesterday.month}-${yesterday.day}';
      final yesterdayIntake = prefs.getInt('dailyWaterIntake') ?? 0;
      await prefs.setInt('water_$yesterdayKey', yesterdayIntake);

      // Reset daily water intake if it's a new day
      await prefs.setInt('dailyWaterIntake', 0);
      await prefs.setInt('lastUsedDate', today);
      setState(() {
        _dailyWaterIntake = 0;
      });
    } else {
      setState(() {
        _dailyWaterIntake = prefs.getInt('dailyWaterIntake') ?? 0;
      });
    }

    setState(() {
      _dailyWaterIntakeTarget = prefs.getInt('dailyWaterIntakeTarget') ?? 2000;
    });
  }

  Future<void> _saveWaterIntakeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyWaterIntake', _dailyWaterIntake);
    await prefs.setInt('dailyWaterIntakeTarget', _dailyWaterIntakeTarget);

    // Save today's data for historical tracking
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = '${today.year}-${today.month}-${today.day}';
    await prefs.setInt('water_$todayKey', _dailyWaterIntake);

    // Update last used date
    await prefs.setInt('lastUsedDate', today.millisecondsSinceEpoch);
  }

  void _addDrink(int amount) {
    setState(() {
      _dailyWaterIntake += amount;
      _lastDrinkTime = DateTime.now();
      _saveWaterIntakeData();
    });
    _controller.forward(from: 0);
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      'Water Tracker',
      'You haven\'t added a drink in the last hour. Stay hydrated!',
      platformChannelSpecifics,
    );
  }

  Widget _buildMainContent() {
    final theme = Theme.of(context);
    final progress =
        (_dailyWaterIntake / _dailyWaterIntakeTarget).clamp(0.0, 1.0);

    return Container(
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
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              automaticallyImplyLeading: false,
              title: Text(
                'Water Tracker',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Daily Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn().slideY(),
                    const SizedBox(height: 8),
                    Text(
                      '$_dailyWaterIntake ml',
                      style: GoogleFonts.poppins(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ).animate().fadeIn().scale(),
                    const SizedBox(height: 32),
                    AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _WaterProgressPainter(
                                progress: progress * _animation.value,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${(progress * 100).toInt()}%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      'of daily goal',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        _WaterButton(
                          amount: 250,
                          onTap: () => _addDrink(250),
                        ),
                        _WaterButton(
                          amount: 500,
                          onTap: () => _addDrink(500),
                        ),
                      ],
                    ).animate().fadeIn().slideY(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildMainContent(),
      const StatisticsScreen(),
      SetupScreen(onThemeModeChanged: widget.onThemeModeChanged),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Tracker',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_drink_outlined),
            selectedIcon: Icon(Icons.local_drink),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
