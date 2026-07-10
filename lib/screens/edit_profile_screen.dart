import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _asalController;
  
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _photoPath;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _asalController = TextEditingController();
    _loadUser();
  }
  
  Future<void> _loadUser() async {
    final userId = AppState.currentUserId;
    if (userId != null) {
      final user = await DatabaseHelper.instance.getUserById(userId);
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _emailController.text = user.emailOrPhone;
          _asalController.text = user.asal ?? '';
          _photoPath = user.photo;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      final updatedUser = UserModel(
        id: _currentUser!.id,
        name: _nameController.text.trim(),
        emailOrPhone: _emailController.text.trim(),
        passwordHash: _currentUser!.passwordHash,
        photo: _photoPath,
        asal: _asalController.text.trim(),
      );
      
      await DatabaseHelper.instance.updateUser(updatedUser);
      
      // Update global state
      AppState.currentUserName = updatedUser.name;
      AppState.refreshNotifier.value++; // trigger refresh di profile screen
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _asalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                            backgroundImage: _photoPath != null 
                                ? FileImage(File(_photoPath!)) 
                                : null,
                            child: _photoPath == null 
                                ? const Icon(Icons.person, size: 50, color: AppColors.primary) 
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      icon: Icons.person_outline,
                      validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email atau No HP',
                      icon: Icons.email_outlined,
                      validator: (value) => value!.isEmpty ? 'Email/No HP tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _asalController,
                      label: 'Asal / Lokasi',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
