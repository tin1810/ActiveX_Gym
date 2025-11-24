import 'package:flutter/material.dart';
import '../../services/mock_api.dart';
import '../../models/er_models.dart';
import '../../services/auth.dart';

class ChallengeFormPage extends StatefulWidget {
  const ChallengeFormPage({super.key});

  @override
  State<ChallengeFormPage> createState() => _ChallengeFormPageState();
}

class _ChallengeFormPageState extends State<ChallengeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: start ? _start : _end,
    );
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final challenge = CommunityChallengeModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      startDate: _start.toIso8601String(),
      endDate: _end.toIso8601String(),
      participants: [ChallengeUserModel(userId: MockAuthService.instance.currentUser.id, progress: 0)],
    );
    await const MockApiService().addChallenge(challenge);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Challenge'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      backgroundColor: const Color(0xFFF7F7F7),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Basic Information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                TextFormField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Title'), validator: _required),
                const SizedBox(height: 12),
                TextFormField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Description')), 
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _dateField('Start Date', _start, () => _pickDate(start: true))),
                  const SizedBox(width: 12),
                  Expanded(child: _dateField('End Date', _end, () => _pickDate(start: false))),
                ]),
              ])),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7ED957),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save Challenge'),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
          child: Row(children: [
            const Icon(Icons.event, color: Colors.grey),
            const SizedBox(width: 8),
            Text('${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}'),
            const Spacer(),
            const Icon(Icons.expand_more),
          ]),
        ),
      ),
    ]);
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
      ]),
      child: child,
    );
  }
}


