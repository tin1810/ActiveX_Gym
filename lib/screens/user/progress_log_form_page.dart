import 'package:flutter/material.dart';
import '../../models/er_models.dart';
import '../../services/auth.dart';
import '../../services/network_service.dart';

class ProgressLogFormPage extends StatefulWidget {
  const ProgressLogFormPage({super.key, this.log});

  final ProgressLogModel? log; // If provided, we're editing

  @override
  State<ProgressLogFormPage> createState() => _ProgressLogFormPageState();
}

class _ProgressLogFormPageState extends State<ProgressLogFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.log != null) {
      _weightCtrl.text = widget.log!.weightKg.toStringAsFixed(1);
      _caloriesCtrl.text = widget.log!.caloriesBurned.toString();
      _notesCtrl.text = widget.log!.notes ?? '';
      // Parse date from string (assuming format like "2024-01-15")
      try {
        _selectedDate = DateTime.parse(widget.log!.date);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _caloriesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = MockAuthService.instance.currentUser.id;
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    
    final weight = double.tryParse(_weightCtrl.text);
    final calories = int.tryParse(_caloriesCtrl.text);
    
    // Validate required fields
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid weight'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (calories == null || calories < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid calories burned'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final log = ProgressLogModel(
      userId: userId,
      date: dateStr,
      weightKg: weight,
      caloriesBurned: calories,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      bodyFatPercentage: null, // Optional field, not in current form
      muscleMass: null, // Optional field, not in current form
    );

    try {
      final api = const ApiServiceFor();
      
      if (widget.log != null && widget.log!.id != null) {
        // Update existing log
        final updatedLog = ProgressLogModel(
          id: widget.log!.id,
          userId: userId,
          date: dateStr,
          weightKg: weight,
          caloriesBurned: calories,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          bodyFatPercentage: widget.log!.bodyFatPercentage,
          muscleMass: widget.log!.muscleMass,
        );
        await api.updateProgressLog(updatedLog);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress log updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Create new log
        await api.addProgressLog(log);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress log saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
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
      appBar: AppBar(
        title: Text(widget.log == null ? 'Log Daily Progress' : 'Update Progress Log'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F7F7),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'Date',
              child: InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Weight',
              child: TextFormField(
                controller: _weightCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'e.g., 70.5',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your weight';
                  }
                  final weight = double.tryParse(v);
                  if (weight == null || weight <= 0) {
                    return 'Please enter a valid weight';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Calories',
              child: TextFormField(
                controller: _caloriesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories Burned',
                  hintText: 'e.g., 500',
                  border: OutlineInputBorder(),
                  suffixText: 'kcal',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter calories burned';
                  }
                  final calories = int.tryParse(v);
                  if (calories == null || calories < 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Notes (Optional)',
              child: TextFormField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add any additional notes about your progress...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.log == null ? 'Save Progress Log' : 'Update Progress Log',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

