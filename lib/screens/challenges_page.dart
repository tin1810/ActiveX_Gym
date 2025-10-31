import 'package:flutter/material.dart';
import '../services/mock_api.dart';
import '../services/auth.dart';
import '../models/er_models.dart';
import '../utils/app_text_style.dart';
import 'challenge_form_page.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  @override
  Widget build(BuildContext context) {
    final api = const MockApiService();
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
        future: api.fetchChallenges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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
                                    await api.deleteChallenge(c.id);
                                    setState(() {});
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
  DateTime start = DateTime.tryParse(c.startDate) ?? DateTime.now();
  DateTime end = DateTime.tryParse(c.endDate) ?? DateTime.now().add(const Duration(days: 30));
  final api = const MockApiService();
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Edit Challenge'),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text('Start: ${start.year}-${start.month}-${start.day}')),
              IconButton(
                icon: const Icon(Icons.event),
                onPressed: () async {
                  final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: start);
                  if (d != null) start = d;
                },
              )
            ]),
            Row(children: [
              Expanded(child: Text('End: ${end.year}-${end.month}-${end.day}')),
              IconButton(
                icon: const Icon(Icons.event),
                onPressed: () async {
                  final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: end);
                  if (d != null) end = d;
                },
              )
            ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await api.updateChallenge(
                id: c.id,
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                startDate: start.toIso8601String(),
                endDate: end.toIso8601String(),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}


