import 'package:flutter/material.dart';
import '../../services/network_service.dart';
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
    
    // Validate dates
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      // Format dates as YYYY-MM-DD for API
      String formatDate(DateTime date) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      
      final challenge = CommunityChallengeModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        startDate: formatDate(_start),
        endDate: formatDate(_end),
        participants: [], // API will handle participants
      );
      
      await const ApiServiceFor().addChallenge(challenge);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge created successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Stack vertically on very small screens (< 400px width)
                    if (constraints.maxWidth < 400) {
                      return Column(
                        children: [
                          _dateField('Start Date', _start, () => _pickDate(start: true)),
                          const SizedBox(height: 12),
                          _dateField('End Date', _end, () => _pickDate(start: false)),
                        ],
                      );
                    }
                    // Show side by side on larger screens
                    return Row(
                      children: [
                        Expanded(child: _dateField('Start Date', _start, () => _pickDate(start: true))),
                        const SizedBox(width: 12),
                        Expanded(child: _dateField('End Date', _end, () => _pickDate(start: false))),
                      ],
                    );
                  },
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.event, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, size: 20),
            ],
          ),
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


