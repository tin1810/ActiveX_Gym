import 'package:flutter/material.dart';
import '../../services/network_service.dart';
import '../../services/auth.dart';
import '../../services/database_helper.dart';
import '../../models/er_models.dart';
import '../../utils/app_text_style.dart';
import 'progress_log_form_page.dart';

class ProgressLogsPage extends StatefulWidget {
  const ProgressLogsPage({super.key});

  @override
  State<ProgressLogsPage> createState() => _ProgressLogsPageState();
}

class _ProgressLogsPageState extends State<ProgressLogsPage> {
  final api = const ApiServiceFor();

  Future<void> _refresh() async {
    setState(() {});
  }

  Future<void> _deleteLog(ProgressLogModel log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Progress Log'),
        content: Text('Are you sure you want to delete the log for ${log.date}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // Delete from database
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'progress_logs',
        where: 'user_id = ? AND date = ?',
        whereArgs: [log.userId, log.date],
      );
      if (mounted) {
        _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = MockAuthService.instance.currentUser.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Logs'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const ProgressLogFormPage()),
              );
              if (result == true) {
                _refresh();
              }
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add Log',
          ),
        ],
      ),
      body: FutureBuilder<List<ProgressLogModel>>(
        future: api.fetchProgressLogs(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data!;
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_weight_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No progress logs yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first log',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final l = logs[i];
                return InkWell(
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ProgressLogFormPage(log: l),
                      ),
                    );
                    if (result == true) {
                      _refresh();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calendar_today, color: Color(0xFF1976D2), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(l.date),
                                style: AppTextStyle.semiBoldText(size: 16, color: Colors.black),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.monitor_weight, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${l.weightKg.toStringAsFixed(1)} kg',
                                    style: AppTextStyle.mediumText(size: 13, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.local_fire_department, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${l.caloriesBurned} kcal',
                                    style: AppTextStyle.mediumText(size: 13, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              if (l.notes != null && l.notes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  l.notes!,
                                  style: AppTextStyle.regularText(size: 12, color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProgressLogFormPage(log: l),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _refresh();
                                }
                              });
                            } else if (value == 'delete') {
                              _deleteLog(l);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ProgressLogFormPage()),
          );
          if (result == true) {
            _refresh();
          }
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final logDate = DateTime(date.year, date.month, date.day);
      
      if (logDate == today) {
        return 'Today';
      } else if (logDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      } else {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}


