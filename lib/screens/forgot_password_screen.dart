import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/app_widgets.dart';
import '../database/database_helper.dart';
import '../theme/app_colors.dart';
import '../widgets/grainy_background.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  int _step = 1; // 1: Email, 2: Code, 3: New Password
  String _generatedCode = '';
  int? _userId;
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email/Nomor HP wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = await DatabaseHelper.instance.getUserByEmailOrPhone(email);
    setState(() => _isLoading = false);

    if (user != null) {
      _userId = user.id;
      _generatedCode = (100000 + Random().nextInt(900000)).toString(); // 6 digit code

      // SMTP Configuration (Ganti dengan email & app password Anda)
      String username = 'email_anda@gmail.com'; // TODO: Ganti dengan Gmail Anda
      String password = 'password_app_anda';    // TODO: Ganti dengan App Password Gmail Anda

      final smtpServer = gmail(username, password);
      
      final message = Message()
        ..from = Address(username, 'Run Tracker App')
        ..recipients.add(email)
        ..subject = 'Kode Verifikasi Lupa Password'
        ..html = "<h3>Kode verifikasi Anda adalah: <b>$_generatedCode</b></h3>\n<p>Jangan berikan kode ini kepada siapapun.</p>";

      try {
        await send(message, smtpServer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kode Verifikasi telah dikirim ke email Anda'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _step = 2;
          });
        }
      } on MailerException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim email. Pastikan SMTP dikonfigurasi. (Demo Kode: $_generatedCode)'),
              backgroundColor: Colors.red,
            ),
          );
          // Tetap lanjut ke step 2 agar bisa dicoba walau email gagal
          setState(() {
            _step = 2;
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun tidak ditemukan')),
        );
      }
    }
  }

  void _verifyCode() {
    final code = _codeController.text.trim();
    if (code == _generatedCode) {
      setState(() {
        _step = 3;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode verifikasi salah')),
      );
    }
  }

  void _resetPassword() async {
    final newPassword = _newPasswordController.text;
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await DatabaseHelper.instance.updatePassword(_userId!, newPassword);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diubah, silakan login kembali'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Back to login
    }
  }

  @override
  Widget build(BuildContext context) {
    return GrainyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_step > 1) {
                setState(() {
                  _step--;
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  _step == 1 
                      ? 'Lupa Password' 
                      : _step == 2 
                          ? 'Verifikasi Kode' 
                          : 'Buat Password Baru',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _step == 1
                      ? 'Masukkan email atau nomor HP yang terdaftar untuk menerima kode verifikasi.'
                      : _step == 2
                          ? 'Masukkan 6 digit kode verifikasi yang telah dikirimkan ke email/nomor HP Anda.'
                          : 'Masukkan password baru Anda minimal 6 karakter.',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 48),

                if (_step == 1) ...[
                  AppTextField(
                    hintText: 'Email / Nomor HP',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: AppColors.primary)
                        : AppPrimaryButton(
                            label: 'Kirim Kode',
                            onPressed: _sendCode,
                          ),
                  ),
                ] else if (_step == 2) ...[
                  AppTextField(
                    hintText: 'Kode Verifikasi',
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppPrimaryButton(
                      label: 'Verifikasi',
                      onPressed: _verifyCode,
                    ),
                  ),
                ] else if (_step == 3) ...[
                  AppTextField(
                    hintText: 'Password Baru',
                    controller: _newPasswordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Colors.grey),
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
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: AppColors.primary)
                        : AppPrimaryButton(
                            label: 'Simpan Password',
                            onPressed: _resetPassword,
                          ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
