import 'package:flutter/material.dart';
import '../widgets/gradient_curve_header.dart';
import '../widgets/app_widgets.dart';
import '../database/database_helper.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _isLoading = false;

  void _register() async {
    final name = _nameController.text.trim();
    final emailOrPhone = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || emailOrPhone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final error = await DatabaseHelper.instance.registerUser(
      name: name,
      emailOrPhone: emailOrPhone,
      password: password,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error is! String) {
      // error contains UserModel if success
      AppState.currentUserId = error.id;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
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
            GradientCurveHeader(
              height: 220,
              showBackButton: true,
              onBack: () => Navigator.pushReplacementNamed(context, '/login'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                            context, '/login'),
                        child: const Text(
                          'sign in',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  AppTextField(hintText: 'Name', controller: _nameController),
                  const SizedBox(height: 16),
                  AppTextField(
                    hintText: 'Email or phone',
                    controller: _emailController,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    hintText: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline,
                        size: 20, color: Colors.grey),
                    suffixWidget: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 48),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : AppPrimaryButton(
                            label: 'Sign up', onPressed: _register),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
