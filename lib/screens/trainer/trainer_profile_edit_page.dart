import 'package:flutter/material.dart';
import '../../services/profile_store.dart';
import '../../services/network_service.dart';
import '../../models/er_models.dart';

class TrainerProfileEditPage extends StatefulWidget {
  const TrainerProfileEditPage({super.key});
  @override
  State<TrainerProfileEditPage> createState() => _TrainerProfileEditPageState();
}

class _TrainerProfileEditPageState extends State<TrainerProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _title;
  late final TextEditingController _bio;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _location;

  @override
  void initState() {
    super.initState();
    final p = ProfileStore.trainer;
    _name = TextEditingController(text: p.name);
    _title = TextEditingController(text: p.title);
    _bio = TextEditingController(text: p.bio);
    _email = TextEditingController(text: p.email);
    _phone = TextEditingController(text: p.phone);
    _location = TextEditingController(text: p.location);
  }

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _bio.dispose();
    _email.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ProfileStore.trainer
      ..name = _name.text.trim()
      ..title = _title.text.trim()
      ..bio = _bio.text.trim()
      ..email = _email.text.trim()
      ..phone = _phone.text.trim()
      ..location = _location.text.trim();
    const ApiServiceFor()
        .updateTrainerProfile(TrainerProfileModel(
          name: ProfileStore.trainer.name,
          title: ProfileStore.trainer.title,
          bio: ProfileStore.trainer.bio,
          email: ProfileStore.trainer.email,
          phone: ProfileStore.trainer.phone,
          location: ProfileStore.trainer.location,
          clients: ProfileStore.trainer.clients,
          plans: ProfileStore.trainer.plans,
          rating: ProfileStore.trainer.rating,
          avatarUrl: null,
        ))
        .then((_) => Navigator.of(context).pop(true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Title/Role'), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _bio, decoration: const InputDecoration(labelText: 'Bio'), maxLines: 4),
              const SizedBox(height: 12),
              TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _save, child: const Text('Save')), 
              )
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;
}


