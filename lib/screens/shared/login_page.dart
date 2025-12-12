import 'package:flutter/material.dart';
import '../../services/auth.dart';
import '../../utils/app_text_style.dart';
import '../../main.dart';
import '../trainer/trainer_main_screen.dart';
import '../admin/admin_user_management_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      await MockAuthService.instance.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Color(0xFF7ED957),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Navigate based on user role
      final isTrainer = MockAuthService.instance.isTrainer;
      final isAdmin = MockAuthService.instance.isAdmin;
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isAdmin 
              ? const AdminUserManagementPage() 
              : (isTrainer ? const TrainerMainScreen() : const MainScreen()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Extract clean error message
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception:')) {
        errorMessage = errorMessage.substring(12);
      }
      
      // Show user-friendly error message
      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    // Clean up error message
    String cleanMessage = message;
    if (cleanMessage.startsWith('Exception: ')) {
      cleanMessage = cleanMessage.substring(12);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cleanMessage,
                style: const TextStyle(fontSize: 14),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: Duration(seconds: cleanMessage.length > 100 ? 6 : 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  OutlineInputBorder _roundedBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 1),
      );

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF7ED957);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1579758629938-03607ccdbaba?q=80&w=1200&auto=format&fit=crop',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.45)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('ActiveXtra', style: AppTextStyle.boldText(size: 26, color: Colors.white)),
                  const SizedBox(height: 18),
                  Text('Welcome Back', style: AppTextStyle.boldText(size: 22, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Sign in to continue your fitness journey', style: AppTextStyle.regularText(size: 13, color: Colors.white70)),
                  const SizedBox(height: 22),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Email', style: AppTextStyle.mediumText(size: 13, color: Colors.white)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailCtrl,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            filled: true,
                            fillColor: Colors.white,
                            border: _roundedBorder(Colors.transparent),
                            enabledBorder: _roundedBorder(Colors.white70),
                            focusedBorder: _roundedBorder(brandGreen),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Email is required' : null,
                        ),
                        const SizedBox(height: 12),
                        // Password
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Password', style: AppTextStyle.mediumText(size: 13, color: Colors.white)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            filled: true,
                            fillColor: Colors.white,
                            border: _roundedBorder(Colors.transparent),
                            enabledBorder: _roundedBorder(Colors.white70),
                            focusedBorder: _roundedBorder(brandGreen),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Forgot Password?', style: TextStyle(color: brandGreen)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Text('Sign In'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(children: [Expanded(child: Divider(color: Colors.white30)), const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR', style: TextStyle(color: Colors.white70))), Expanded(child: Divider(color: Colors.white30))]),
                        const SizedBox(height: 14),
                        // _SocialButton(icon: Icons.g_mobiledata, label: 'Continue with Google'),
                        // const SizedBox(height: 10),
                        // _SocialButton(icon: Icons.apple, label: 'Continue with Apple'),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
                              child: const Text('Sign Up', style: TextStyle(color: brandGreen, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Role chips removed; role selection handled by sample email rule in MockAuthService

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: Colors.black, size: 22),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}


