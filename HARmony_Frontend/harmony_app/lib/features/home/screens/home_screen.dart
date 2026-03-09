import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:async';
import 'dart:math';
import 'package:harmony_app/shared/widgets/theme_provider.dart' show themeProviderProvider, themeModeProvider, ThemeProvider;
import 'package:harmony_app/shared/widgets/activity_card.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/features/activity_recognition/models/sensor_window.dart';
import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State
  String _currentActivity = 'Unknown';
  double _confidence = 0.0;
  int _stepCount = 0;
  int _activeMinutes = 0;
  double _accuracy = 0.0;
  double _responseTime = 0.0;
  bool _isBackendConnected = false;
  String _backendStatus = 'Checking...';
  bool _isConnecting = false;

  // Bottom navigation state
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Update step count periodically
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _stepCount += Random().nextInt(10) + 1;
        });
      }
    });

    _checkBackendConnection();
  }

  Future<void> _checkBackendConnection() async {
    if (!mounted) return;
    setState(() {
      _isConnecting = true;
      _backendStatus = 'Connecting to backend...';
    });

    final api = ref.read(apiServiceProvider);
    final isConnected = await api.checkConnection();

    if (mounted) {
      setState(() {
        _isBackendConnected = isConnected;
        _isConnecting = false;
        _backendStatus = isConnected
            ? 'Connected to real-time HAR backend at ${api.baseUrl}'
            : 'Backend offline. Running in local-only mode.';
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ref.watch(themeProviderProvider);
    final backgroundColor = themeProvider.backgroundColor;
    final cardColor = themeProvider.cardColor;
    final textPrimary = themeProvider.textPrimary;
    final textSecondary = themeProvider.textSecondary;

    // Listen to activity predictions
    ref.listen<AsyncValue<ActivityModel>>(activityPredictionProvider, (previous, next) {
      next.when(
        data: (activityModel) {
          setState(() {
            _currentActivity = activityModel.activity;
            _confidence = activityModel.confidence;
          });
        },
        error: (error, stackTrace) {
          // Keep current values or set to unknown
          setState(() {
            _currentActivity = 'Unknown';
            _confidence = 0.0;
          });
        },
        loading: () {
          // Keep current values
        },
      );
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: _buildDrawer(context, themeProvider),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            snap: false,
            backgroundColor: cardColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'HAR',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: TWColors.blue500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'mony',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: TWColors.emerald500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI Activity Recognition',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: themeProvider.isDarkMode
                        ? [TWColors.slate800, TWColors.slate900]
                        : [TWColors.blue50, TWColors.indigo50, TWColors.emerald50],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.menu, color: textPrimary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            actions: [
              // Backend Status Badge
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isBackendConnected ? TWColors.emerald500.withOpacity(0.1) : TWColors.red500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isBackendConnected ? TWColors.emerald500 : TWColors.red500,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _isBackendConnected ? TWColors.emerald500 : TWColors.red500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      _isBackendConnected ? 'Connected' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isBackendConnected ? TWColors.emerald500 : TWColors.red500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: themeProvider.isDarkMode ? Colors.amber : Colors.grey[700],
                ),
                onPressed: () => ref.read(themeModeProvider.notifier).toggleDarkMode(),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.95, end: 1),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Transform.scale(scale: value, child: child),
                    child: _buildBackendConnectionCard(cardColor, textPrimary, textSecondary),
                  ),
                  const SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.95, end: 1),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Transform.scale(scale: value, child: child),
                    child: _buildActivityCard(cardColor),
                  ),
                  const SizedBox(height: 24),
                  _buildStatsGrid(cardColor, themeProvider),
                  const SizedBox(height: 24),
                  _buildConfidenceCard(cardColor, themeProvider),
                  const SizedBox(height: 24),
                  _buildTestControls(cardColor),
                  const SizedBox(height: 28),
                  _buildCopyrightFooter(textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
      bottomNavigationBar: _buildBottomNavBar(cardColor, themeProvider),
    );
  }

  Widget _buildBackendConnectionCard(Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TWColors.blue500.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BACKEND CONNECTION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isBackendConnected
                        ? TWColors.emerald500.withOpacity(0.1)
                        : TWColors.red500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isBackendConnected ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _isBackendConnected
                          ? TWColors.emerald500
                          : TWColors.red500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _backendStatus,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isConnecting ? null : _checkBackendConnection,
              icon: _isConnecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isBackendConnected ? Icons.refresh : Icons.wifi,
                      size: 18,
                    ),
              label: Text(_isConnecting
                  ? 'Connecting...'
                  : (_isBackendConnected ? 'Reconnect' : 'Connect')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isBackendConnected
                    ? TWColors.blue500
                    : TWColors.emerald500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Color cardColor) {
    return ActivityCard(
      activity: _currentActivity,
      confidence: _confidence,
      stepCount: _stepCount,
      isActive: true,
    );
  }

  Widget _buildStatsGrid(Color cardColor, ThemeProvider themeProvider) {
    final stats = [
      {
        'icon': Icons.directions_walk,
        'value': '$_stepCount',
        'label': 'Steps Today',
        'color': TWColors.blue500,
      },
      {
        'icon': Icons.timer,
        'value': '${_activeMinutes}m',
        'label': 'Active Time',
        'color': TWColors.emerald500,
      },
      {
        'icon': Icons.auto_graph,
        'value': '${(_accuracy * 100).toStringAsFixed(0)}%',
        'label': 'Accuracy',
        'color': TWColors.amber500,
      },
      {
        'icon': Icons.speed,
        'value': '${_responseTime}s',
        'label': 'Response Time',
        'color': TWColors.purple500,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.92, end: 1),
          duration: Duration(milliseconds: 350 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (stat['color'] as Color).withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (stat['color'] as Color).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    stat['value'] as String,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: themeProvider.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfidenceCard(Color cardColor, ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TWColors.emerald500.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MODEL PERFORMANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TWColors.slate600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 100,
                    showLabels: true,
                    showTicks: true,
                    axisLineStyle: AxisLineStyle(
                      thickness: 0.1,
                      color: themeProvider.isDarkMode
                          ? TWColors.slate700
                          : TWColors.slate200,
                      cornerStyle: CornerStyle.bothCurve,
                    ),
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: 0,
                        endValue: 100,
                        color: themeProvider.isDarkMode
                            ? TWColors.slate700
                            : TWColors.slate200,
                      ),
                    ],
                    pointers: <GaugePointer>[
                      RangePointer(
                        value: _confidence * 100,
                        width: 0.25,
                        color: TWColors.emerald500,
                        cornerStyle: CornerStyle.bothCurve,
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        angle: 90,
                        positionFactor: 0.8,
                        widget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_confidence * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: themeProvider.textPrimary,
                              ),
                            ),
                            Text(
                              'Confidence',
                              style: TextStyle(
                                fontSize: 12,
                                color: TWColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTestControls(Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TWColors.emerald500.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TWColors.slate600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                      Navigator.pushNamed(context, '/realtime');
                    },
                    icon: const Icon(Icons.sensors, size: 20),
                    label: const Text('REAL-TIME MONITORING'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TWColors.emerald500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      Navigator.pushNamed(context, '/settings');
                    },
                    icon: const Icon(Icons.settings, size: 20),
                    label: const Text('SETTINGS'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyrightFooter(Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Column(
        children: [
          Divider(
            color: textSecondary.withOpacity(0.2),
            height: 1,
          ),
          const SizedBox(height: 16),
          Text(
            '© 2025 HARmony - AI Activity Recognition',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(Color cardColor, ThemeProvider themeProvider) {
    final navItems = [
      {'icon': Icons.home_filled, 'label': 'Home', 'route': '/'},
      {'icon': Icons.sensors, 'label': 'Real-time', 'route': '/realtime'},
      {'icon': Icons.history, 'label': 'History', 'route': '/history'},
      {'icon': Icons.settings, 'label': 'Settings', 'route': '/settings'},
      {'icon': Icons.psychology, 'label': 'Diagnostics', 'route': '/diagnostic'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              bool isSelected = index == _selectedIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });

                  if (ModalRoute.of(context)?.settings.name != item['route'] as String) {
                    Navigator.pushNamed(context, item['route'] as String);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: isSelected
                      ? BoxDecoration(
                    color: TWColors.blue500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: isSelected
                            ? TWColors.blue500
                            : themeProvider.isDarkMode
                            ? Colors.grey[400]
                            : TWColors.slate500,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? TWColors.blue500
                              : themeProvider.isDarkMode
                              ? Colors.grey[400]
                              : TWColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ThemeProvider themeProvider) {
    return Drawer(
      backgroundColor: themeProvider.cardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: themeProvider.appBarGradient,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'HAR',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: TWColors.blue500,
                        ),
                      ),
                      TextSpan(
                        text: 'mony',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: TWColors.emerald500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Human Activity Recognition',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            Icons.home,
            'Home',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 0;
              });
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
          _buildDrawerItem(
            context,
            Icons.sensors,
            'Real-time Monitoring',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 1;
              });
              Navigator.pushNamed(context, '/realtime');
            },
          ),
          _buildDrawerItem(
            context,
            Icons.history,
            'Activity History',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 2;
              });
              Navigator.pushNamed(context, '/history');
            },
          ),
          _buildDrawerItem(
            context,
            Icons.timeline,
            'Activity Timeline',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/timeline');
            },
          ),
          _buildDrawerItem(
            context,
            Icons.favorite,
            'Health Dashboard',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/health');
            },
          ),
          _buildDrawerItem(
            context,
            Icons.psychology,
            'AI Coach',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/coach');
            },
          ),
          _buildDrawerItem(
            context,
            Icons.insights,
            'Analytics',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/analytics');
            },
          ),
          _buildDrawerItem(
            context,
            Icons.folder_open,
            'Data & Export',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/data');
            },
          ),
          _buildDrawerItem(
            context,
            Icons.person,
            'Profile & Goals',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          _buildDrawerItem(
            context,
            Icons.bug_report,
            'Model Diagnostics',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 4;
              });
              Navigator.pushNamed(context, '/diagnostic');
            },
          ),
          _buildDrawerItem(
            context,
            Icons.settings,
            'Settings',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 3;
              });
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            Icons.info,
            'About',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/about');
            },
          ),
          _buildDrawerItem(
            context,
            Icons.help,
            'Help & Support',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/help');
            },
          ),
          _buildDrawerItem(
            context,
            Icons.privacy_tip,
            'Privacy Policy',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/privacy');
            },
          ),
          _buildDrawerItem(
            context,
            Icons.description,
            'Terms of Service',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/terms');
            },
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            Icons.auto_awesome,
            'Futuristic Health',
            themeProvider.textPrimary,
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/futuristic');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title,
      Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}
