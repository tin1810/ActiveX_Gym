import 'package:flutter/material.dart';
import '../services/mock_api.dart';
import '../services/auth.dart';
import '../models/er_models.dart';
import '../utils/app_text_style.dart';
import 'login_page.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final api = const MockApiService();
  int _tab = 0; // 0=Users, 1=Trainers

  Future<List<UserModel>> _load() async {
    final all = await api.fetchUsers();
    return all.where((u) => _tab == 0 ? u.role == 'user' : u.role == 'trainer').toList();
  }

  Future<void> _createTrainerDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Trainer Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
          ],
        );
      },
    );
    if (saved == true) {
      await api.addTrainer(name: nameCtrl.text.trim(), email: emailCtrl.text.trim(), password: passCtrl.text);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!MockAuthService.instance.isAdmin) {
      return const Scaffold(body: Center(child: Text('Admin only')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - User Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              MockAuthService.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              onPressed: _createTrainerDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Trainer'),
            )
          : null,
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _segBtn('Users', 0),
                const SizedBox(width: 8),
                _segBtn('Trainers', 1),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _load(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data!;
                if (list.isEmpty) {
                  return const Center(child: Text('No records'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final u = list[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                            child: const Icon(Icons.person_outline),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(u.name, style: AppTextStyle.semiBoldText(size: 15, color: Colors.black)),
                              const SizedBox(height: 2),
                              Text(u.email, style: AppTextStyle.regularText(size: 12, color: Colors.grey[700])),
                            ]),
                          ),
                          IconButton(
                            onPressed: () async {
                              await api.deleteUser(u.id);
                              if (mounted) setState(() {});
                            },
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _segBtn(String label, int v) {
    final selected = _tab == v;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _tab = v),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Colors.black : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black,
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
