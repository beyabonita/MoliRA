import 'package:flutter/material.dart';
import 'register.dart';
import 'services/library_service.dart';
import 'theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _studentIdController = TextEditingController(text: '2024-01842');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() => _loading = true);
    try {
      await LibraryService.instance.signIn(
        studentId: _studentIdController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dark green hero banner matching Student · 01 Sign in
              Container(
                color: AppColors.primaryGreen,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHMSU Library',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'LEARN. DISCOVER. GROW.',
                              style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.0),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Your next chapter\nstarts here.',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 30,
                        height: 1.15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(width: 36, height: 2.5, color: const Color(0xFFD4A853)),
                    const SizedBox(height: 14),
                    const Text(
                      'Carlos Hilado Memorial State University\nTalisay campus library',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Find resources, reserve a copy, and keep your borrowing on track.',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 22),

                    const Text('Student ID', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _studentIdController,
                      decoration: const InputDecoration(hintText: 'e.g. 2024-01842'),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Use the student ID linked to your library account.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),

                    const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Visit the Talisay circulation desk for password recovery.')),
                          );
                        },
                        child: const Text('Forgot password?', style: TextStyle(color: AppColors.primaryGreen)),
                      ),
                    ),
                    const SizedBox(height: 6),

                    ElevatedButton.icon(
                      onPressed: _loading ? null : _handleSignIn,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(_loading ? 'Signing in...' : 'Sign in'),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('New to the library? ', style: TextStyle(color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'Create an account',
                            style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EFE6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.help_outline, size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Need access? Visit the Talisay circulation desk for help with your library account.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
