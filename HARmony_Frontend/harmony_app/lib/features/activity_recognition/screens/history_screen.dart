import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart' show themeProviderProvider, ThemeProvider;
import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final List<ActivitySession> _sessions = [];
  final List<ActivitySession> _allSessions = [];
  String _filter = 'all';
  String _sortBy = 'recent';
  bool _isLoading = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final activityStorageService = ref.read(activityStorageServiceProvider);
      final api = ref.read(apiServiceProvider);

      // Try to fetch remote sessions from Flask backend first
      List<ActivitySession> sessionsFromRemote = [];
      try {
        sessionsFromRemote = await api.fetchRemoteSessions();
        if (kDebugMode) print('📥 Loaded ${sessionsFromRemote.length} sessions from Flask backend');
      } catch (e) {
        if (kDebugMode) print('⚠ Failed to fetch remote sessions: $e');
      }

      if (sessionsFromRemote.isNotEmpty) {
        // Sync remote sessions into local storage for offline access
        try {
          await activityStorageService.clearAllSessions();
          for (final session in sessionsFromRemote) {
            await activityStorageService.saveSession(session);
          }
          if (kDebugMode) print('✓ Synced ${sessionsFromRemote.length} sessions to local database');
        } catch (e) {
          if (kDebugMode) print('⚠ Failed to sync remote sessions to local: $e');
        }
      }
      
      // Load from (now updated) local storage
      final sessions = await activityStorageService.getAllSessions();
      if (mounted) {
        setState(() {
          _allSessions.clear();
          _allSessions.addAll(sessions);
          _sessions.clear();
          _sessions.addAll(sessions);
          _sortSessions();
        });
        if (sessions.isEmpty && sessionsFromRemote.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📊 No activity history yet. Start monitoring to record sessions.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ HistoryScreen: Error loading sessions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _filter = filter;
      if (filter == 'all') {
        _sessions.clear();
        _sessions.addAll(_allSessions);
      } else {
        _sessions.clear();
        _sessions.addAll(
          _allSessions.where((session) => session.summary == filter).toList(),
        );
      }
      _sortSessions();
    });
  }

  void _sortSessions() {
    setState(() {
      if (_sortBy == 'recent') {
        _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      } else if (_sortBy == 'duration') {
        _sessions.sort((a, b) => b.duration.compareTo(a.duration));
      } else if (_sortBy == 'activity') {
        _sessions.sort((a, b) => (a.summary ?? '').compareTo(b.summary ?? ''));
      }
    });
  }

  Future<void> _deleteSession(String sessionId, ThemeProvider themeProvider) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Session',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: const Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final activityStorageService = ref.read(activityStorageServiceProvider);
                await activityStorageService.deleteSession(sessionId);
                await _loadSessions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting session: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Activity History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isExporting
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: textPrimary))
                : Icon(Icons.share, color: textPrimary),
            onPressed: _isExporting ? null : _exportCsv,
            tooltip: 'Export as CSV',
          ),
          IconButton(
            icon: Icon(Icons.delete, color: textPrimary),
            onPressed: _sessions.isNotEmpty ? _clearAllHistory : null,
            tooltip: 'Clear All History',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        color: TWColors.blue500,
        child: Column(
          children: [
            // Filters
            _buildFilters(themeProvider),
            const SizedBox(height: 8),

            // Sort Options
            _buildSortOptions(themeProvider),

            // Statistics
            _buildStatistics(themeProvider),

            // Sessions List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (_sessions.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: 320,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history_toggle_off,
                                      size: 64,
                                      color: textSecondary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No sessions found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _filter == 'all'
                                          ? 'Start monitoring to record activities'
                                          : 'No ${_filter.toLowerCase()} sessions found',
                                      style: TextStyle(
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _sessions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) => _SessionCard(
                            session: _sessions[index],
                            themeProvider: themeProvider,
                            onDelete: () => _deleteSession(_sessions[index].id, themeProvider),
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeProvider themeProvider) {
    final List<String> filters = ['all', 'Walking', 'Running', 'Cycling', 'Sitting', 'Standing'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _filter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                filter == 'all' ? 'All Activities' : filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : themeProvider.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _applyFilter(filter),
              backgroundColor: themeProvider.cardColor,
              selectedColor: TWColors.blue500,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? TWColors.blue500 : themeProvider.textSecondary.withOpacity(0.3),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortOptions(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Sort by:',
            style: TextStyle(
              color: themeProvider.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: themeProvider.textSecondary.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                    _sortSessions();
                  });
                },
                dropdownColor: themeProvider.cardColor,
                style: TextStyle(color: themeProvider.textPrimary),
                items: [
                  DropdownMenuItem(
                    value: 'recent',
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: themeProvider.textSecondary),
                        const SizedBox(width: 8),
                        const Text('Most Recent'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'duration',
                    child: Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: themeProvider.textSecondary),
                        const SizedBox(width: 8),
                        const Text('Duration'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'activity',
                    child: Row(
                      children: [
                        Icon(Icons.directions_walk, size: 16, color: themeProvider.textSecondary),
                        const SizedBox(width: 8),
                        const Text('Activity'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(ThemeProvider themeProvider) {
    if (_sessions.isEmpty) return const SizedBox();

    final totalDuration = _sessions.fold(
      Duration.zero,
          (sum, session) => sum + session.duration,
    );

    final totalPredictions = _sessions.fold(
      0,
          (sum, session) => sum + session.predictions.length,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Session Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: themeProvider.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: themeProvider.textSecondary),
                onPressed: _loadSessions,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                '${_sessions.length}',
                'Sessions',
                Icons.history,
                TWColors.blue500,
                themeProvider,
              ),
              _buildStatCard(
                '${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m',
                'Total Time',
                Icons.timer,
                TWColors.emerald500,
                themeProvider,
              ),
              _buildStatCard(
                '$totalPredictions',
                'Predictions',
                Icons.analytics,
                TWColors.indigo500,
                themeProvider,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color, ThemeProvider themeProvider) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: themeProvider.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: themeProvider.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _clearAllHistory() async {
    final themeProvider = ref.read(themeProviderProvider);
    final activityStorageService = ref.read(activityStorageServiceProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All History',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: const Text('This will delete all recorded sessions. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await activityStorageService.clearAllSessions();
                await _loadSessions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All history cleared'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing history: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final activityStorageService = ref.read(activityStorageServiceProvider);
      final csvContent = await activityStorageService.exportSessionsAsCsv();
      final sessions = await activityStorageService.getAllSessions();
      if (sessions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No activity data to export'), backgroundColor: Colors.amber),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final fileName = 'harmony_activities_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csvContent);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'HARmony Activity Data',
        text: 'Activity recognition export from HARmony app.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

class _SessionCard extends StatelessWidget {
  final ActivitySession session;
  final ThemeProvider themeProvider;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.themeProvider,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getActivityColor(session.summary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  session.summary ?? 'Mixed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getActivityColor(session.summary),
                  ),
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: themeProvider.textSecondary),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Delete Session', style: TextStyle(color: themeProvider.textPrimary)),
                      ],
                    ),
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${DateFormat('MMM d').format(session.startTime)} • ${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeProvider.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: themeProvider.textSecondary),
              const SizedBox(width: 8),
              Text(
                '${session.duration.inMinutes} minutes',
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.directions_walk, size: 16, color: themeProvider.textSecondary),
              const SizedBox(width: 8),
              Text(
                '${session.predictions.length} detections',
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: session.predictions.take(5).length,
              itemBuilder: (context, index) {
                final prediction = session.predictions[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? TWColors.slate700 : TWColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getActivityColor(prediction.activity),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        prediction.activity,
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String? activity) {
    switch (activity?.toLowerCase()) {
      case 'walking':
        return TWColors.emerald500;
      case 'running':
        return TWColors.amber500;
      case 'cycling':
        return TWColors.blue500;
      case 'sitting':
        return TWColors.indigo500;
      case 'standing':
        return TWColors.purple500;
      default:
        return TWColors.slate500;
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}
