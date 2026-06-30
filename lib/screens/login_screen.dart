import 'package:flutter/material.dart';
import '../widgets/gradient_curve_header.dart';
import '../widgets/app_widgets.dart';
import '../database/database_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _isLoading = false;

  void _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor & password wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = await DatabaseHelper.instance.loginUser(
      emailOrPhone: phone,
      password: password,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor atau password salah')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GradientCurveHeader(height: 300),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: const Text(
                          'sign up',
                          style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    hintText: '+1',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    hintText: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline,
                        size: 20, color: Colors.grey),
                    suffixWidget: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'FORGOT',
                        style: TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: CircularProgressIndicator(
                              color: Color(0xFF8B5CF6),
                            ),
                          )
                        : AppPrimaryButton(label: 'Login', onPressed: _login),
                  ),
                  const SizedBox(height: 64),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialIcon(Icons.apple, Colors.black),
                        const SizedBox(width: 20),
                        _socialIcon(Icons.facebook, const Color(0xFF1877F2)),
                        const SizedBox(width: 20),
                        _socialIcon(Icons.g_mobiledata, Colors.red, size: 28),
                        const SizedBox(width: 20),
                        _socialIcon(Icons.alternate_email,
                            const Color(0xFF1DA1F2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color, {double size = 20}) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey.shade100,
      child: Icon(icon, color: color, size: size),
    );
  }
}
