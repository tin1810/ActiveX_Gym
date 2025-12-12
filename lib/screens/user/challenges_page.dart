import 'package:flutter/material.dart';
import '../../services/network_service.dart';
import '../../services/auth.dart';
import '../../models/er_models.dart';
import '../../utils/app_text_style.dart';
import '../trainer/challenge_form_page.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final api = const ApiServiceFor();

  Future<void> _deleteChallenge(BuildContext context, String id) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Challenge'),
          content: const Text('Are you sure you want to delete this challenge? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await api.deleteChallenge(id);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(12);
      } else if (errorMessage.startsWith('Exception:')) {
        errorMessage = errorMessage.substring(10);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = const ApiServiceFor();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Challenges'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: (MockAuthService.instance.isTrainer || MockAuthService.instance.isAdmin)
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const ChallengeFormPage()),
                );
                if (created == true) (context as Element).reassemble();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
      body: FutureBuilder<List<CommunityChallengeModel>>(
        future: api.fetchChallenges(limit: 20),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading challenges',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No challenges found'));
          }
          final items = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final c = items[i];
              final avgProgress = c.participants.isEmpty
                  ? 0
                  : (c.participants.map((e) => e.progress).reduce((a, b) => a + b) / c.participants.length).round();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.emoji_events, color: Color(0xFFFF9800)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(c.title, style: AppTextStyle.semiBoldText(size: 16, color: Colors.black))),
                        (MockAuthService.instance.isTrainer || MockAuthService.instance.isAdmin)
                            ? PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    await _editDialog(context, c);
                                    setState(() {});
                                  } else if (v == 'delete') {
                                    await _deleteChallenge(context, c.id);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyle.regularText(size: 13, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: avgProgress / 100.0,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.people_alt, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('${c.participants.length} participants', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[800])),
                        const Spacer(),
                        Text('$avgProgress% complete', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[800])),
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

Future<void> _editDialog(BuildContext context, CommunityChallengeModel c) async {
  final titleCtrl = TextEditingController(text: c.title);
  final descCtrl = TextEditingController(text: c.description);
  
  // Parse dates - handle both YYYY-MM-DD and ISO8601 formats
  DateTime parseDate(String dateString) {
    try {
      // Try parsing as YYYY-MM-DD first
      final parts = dateString.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
      // Fallback to ISO8601
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }
  
  DateTime start = parseDate(c.startDate);
  DateTime end = parseDate(c.endDate);
  final api = const ApiServiceFor();
  
  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Challenge'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description *'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateFieldRow(
                          label: 'Start Date',
                          date: start,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: start,
                            );
                            if (d != null) {
                              setDialogState(() => start = d);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateFieldRow(
                          label: 'End Date',
                          date: end,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: end,
                            );
                            if (d != null) {
                              setDialogState(() => end = d);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validate fields
                  if (titleCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Title is required'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  if (descCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Description is required'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  if (end.isBefore(start)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('End date must be after start date'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  
                  try {
                    // Format dates as YYYY-MM-DD
                    String formatDate(DateTime date) {
                      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    }
                    
                    await api.updateChallenge(
                      id: c.id,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      startDate: formatDate(start),
                      endDate: formatDate(end),
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Challenge updated successfully'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    String errorMessage = e.toString();
                    if (errorMessage.startsWith('Exception: ')) {
                      errorMessage = errorMessage.substring(12);
                    } else if (errorMessage.startsWith('Exception:')) {
                      errorMessage = errorMessage.substring(10);
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $errorMessage'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildDateFieldRow({
  required String label,
  required DateTime date,
  required VoidCallback onTap,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.event, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}


