import 'package:flutter/material.dart';
import '../../services/mock_api.dart';
import '../../models/er_models.dart';
import '../../utils/app_text_style.dart';

class ProgressLogsPage extends StatelessWidget {
  const ProgressLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = const MockApiService();
    const userId = 'u1';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Logs'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<ProgressLogModel>>(
        future: api.fetchProgressLogs(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final logs = snapshot.data!;
          if (logs.isEmpty) return const Center(child: Text('No logs yet'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final l = logs[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.date, style: AppTextStyle.semiBoldText(size: 14, color: Colors.black)),
                        Text('${l.caloriesBurned} kcal', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[700])),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.monitor_weight, size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${l.weightKg.toStringAsFixed(1)} kg', style: AppTextStyle.semiBoldText(size: 14, color: Colors.black)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}


