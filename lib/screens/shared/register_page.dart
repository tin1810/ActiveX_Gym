import 'package:flutter/material.dart';
import '../../services/auth.dart';
import '../../utils/app_text_style.dart';
import '../../main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _agree = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) return;
    
    // Check if user agreed to terms
    if (!_agree) {
      _showError('Please agree to the Terms & Conditions and Privacy Policy');
      return;
    }
    
    setState(() => _loading = true);
    
    try {
      // Call API registration (which also saves to SQLite)
      await MockAuthService.instance.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Welcome to ActiveXtra'),
          backgroundColor: Color(0xFF7ED957),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to main screen after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      
      // Extract clean error message
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(12);
      }
      
      // Show user-friendly error message
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
            'https://images.unsplash.com/photo-1620188467120-5042ed1eb5da?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=687',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.45)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ActiveXtra', style: AppTextStyle.boldText(size: 26, color: Colors.white)),
                    const SizedBox(height: 18),
                    Text('Create Account', style: AppTextStyle.boldText(size: 22, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('Start your fitness journey today', style: AppTextStyle.regularText(size: 13, color: Colors.white70)),
                    const SizedBox(height: 18),
                    // Full Name
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Full Name', style: AppTextStyle.mediumText(size: 13, color: Colors.white)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name', filled: true, fillColor: Colors.white,
                        border: _roundedBorder(Colors.transparent), enabledBorder: _roundedBorder(Colors.white70), focusedBorder: _roundedBorder(brandGreen),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    // Email
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Email', style: AppTextStyle.mediumText(size: 13, color: Colors.white)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email', filled: true, fillColor: Colors.white,
                        border: _roundedBorder(Colors.transparent), enabledBorder: _roundedBorder(Colors.white70), focusedBorder: _roundedBorder(brandGreen),
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
                      decoration: InputDecoration(
                        hintText: 'Create a password', filled: true, fillColor: Colors.white,
                        border: _roundedBorder(Colors.transparent), enabledBorder: _roundedBorder(Colors.white70), focusedBorder: _roundedBorder(brandGreen),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
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
                    ),
                    const SizedBox(height: 6),
                    Text('Must be at least 8 characters', style: AppTextStyle.regularText(size: 12, color: Colors.white70)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false), activeColor: brandGreen),
                        Expanded(
                          child: Wrap(
                            children: const [
                              Text('I agree to the ', style: TextStyle(color: Colors.white70)),
                              Text('Terms & Conditions', style: TextStyle(color: brandGreen, fontWeight: FontWeight.w700)),
                              Text(' and ', style: TextStyle(color: Colors.white70)),
                              Text('Privacy Policy', style: TextStyle(color: brandGreen, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_loading || !_agree) ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandGreen,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey.shade400,
                          disabledForegroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: Divider(color: Colors.white30)), const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR', style: TextStyle(color: Colors.white70))), Expanded(child: Divider(color: Colors.white30))]),
                    const SizedBox(height: 12),
                    // _SocialButton(icon: Icons.g_mobiledata, label: 'Continue with Google'),
                    // const SizedBox(height: 10),
                    // _SocialButton(icon: Icons.apple, label: 'Continue with Apple'),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(color: Colors.white70)),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text('Sign In', style: TextStyle(color: brandGreen, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    // Role selection removed; new accounts default to user role.
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4CAF50) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

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


