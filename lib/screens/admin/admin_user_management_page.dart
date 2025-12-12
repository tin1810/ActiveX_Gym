import 'package:flutter/material.dart';
import '../../services/network_service.dart';
import '../../services/auth.dart';
import '../../models/er_models.dart';
import '../../utils/app_text_style.dart';
import '../shared/login_page.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final api = const ApiServiceFor();
  int _tab = 0; // 0=Users, 1=Trainers
  int _refreshKey = 0; // Key to force FutureBuilder refresh

  Future<List<UserModel>> _load() async {
    // Fetch users by role from API
    final role = _tab == 0 ? 'user' : 'trainer';
    return await api.fetchUsers(role: role);
  }
  
  void _refreshList() {
    setState(() {
      _refreshKey++; // Increment key to force FutureBuilder to rebuild
    });
  }

  Future<void> _createTrainerDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Trainer Account'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter trainer name',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter trainer email',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                      enabled: !loading,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter password (min 8 characters)',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                      enabled: !loading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => loading = true);
                            try {
                              await api.addTrainer(
                                name: nameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                password: passCtrl.text,
                              );
                              if (context.mounted) {
                                Navigator.pop(context, true);
                              }
                            } catch (e) {
                              setDialogState(() => loading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_getErrorMessage(e)),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
    
    if (saved == true) {
      if (mounted) {
        _refreshList(); // Refresh the list to show newly created trainer
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trainer account created successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getErrorMessage(dynamic e) {
    String errorMessage = e.toString();
    if (errorMessage.startsWith('Exception: ')) {
      errorMessage = errorMessage.substring(12);
    } else if (errorMessage.startsWith('Exception:')) {
      errorMessage = errorMessage.substring(10);
    }
    return errorMessage;
  }

  Future<void> _deleteUserDialog(UserModel user) async {
    final role = user.role == 'trainer' ? 'Trainer' : 'User';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete $role Account'),
          content: Text(
            'Are you sure you want to delete ${user.name} (${user.email})? This action cannot be undone.',
          ),
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
    if (confirmed == true) {
      try {
        await api.deleteUser(user.id);
        if (mounted) {
          _refreshList(); // Refresh the list to remove deleted user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$role account deleted successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: ${_getErrorMessage(e)}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _logoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out from the admin account?'),
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
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await MockAuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
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
            onPressed: _logoutDialog,
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
              key: ValueKey(_refreshKey), // Force rebuild when key changes
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
                            onPressed: () => _deleteUserDialog(u),
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
        onPressed: () {
          setState(() {
            _tab = v;
            _refreshKey++; // Refresh list when switching tabs
          });
        },
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
