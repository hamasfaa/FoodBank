import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/core/utils/validators.dart';
import 'package:foodbank/core/widgets/receiver_navigation_bar.dart';
import 'package:foodbank/features/auth/domain/entities/user_entity.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_event.dart';

class ReceiverProfilePage extends StatefulWidget {
  const ReceiverProfilePage({super.key});

  @override
  State<ReceiverProfilePage> createState() => _ReceiverProfilePageState();
}

class _ReceiverProfilePageState extends State<ReceiverProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();

  UserEntity? _localUser;
  File? _selectedPhoto;
  bool _initialized = false;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final user = context.read<AuthBloc>().state.user;
    _setUser(user);
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _setUser(UserEntity? user) {
    _localUser = user;
    _nameController.text = user?.fullName ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 768,
      );
      if (picked != null) {
        setState(() => _selectedPhoto = File(picked.path));
      }
    } catch (e) {
      if (mounted) _showSnack('Gagal memilih foto: $e', isError: true);
    }
  }

  Future<void> _saveProfile() async {
    final user = _localUser;
    if (user == null || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      var photoUrl = user.photoUrl;
      final photo = _selectedPhoto;

      if (photo != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_photos/${user.uid}.jpg');
        await ref.putFile(photo, SettableMetadata(contentType: 'image/jpeg'));
        photoUrl = await ref.getDownloadURL();
      }

      final fullName = _nameController.text.trim();
      final phoneNumber = _phoneController.text.trim();

      final updateData = <String, dynamic>{
        'fullName': fullName,
        'phoneNumber': phoneNumber,
      };
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      final firebaseUser = FirebaseAuth.instance.currentUser;
      await firebaseUser?.updateDisplayName(fullName);
      if (photoUrl != null) await firebaseUser?.updatePhotoURL(photoUrl);

      final updatedUser = UserEntity(
        uid: user.uid,
        fullName: fullName,
        email: user.email,
        phoneNumber: phoneNumber,
        role: user.role,
        createdAt: user.createdAt,
        isActive: user.isActive,
        photoUrl: photoUrl,
      );

      if (!mounted) return;
      context.read<AuthBloc>().add(AuthUserProfileUpdated(updatedUser));
      setState(() {
        _localUser = updatedUser;
        _selectedPhoto = null;
        _isEditing = false;
      });
      _showSnack('Profil berhasil diperbarui');
    } catch (e) {
      if (mounted) _showSnack('Gagal memperbarui profil', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Apakah kamu yakin ingin keluar dari akun ini?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _selectedPhoto = null;
      _nameController.text = _localUser?.fullName ?? '';
      _phoneController.text = _localUser?.phoneNumber ?? '';
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _localUser ?? context.watch<AuthBloc>().state.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profil Saya',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              tooltip: 'Edit profil',
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      bottomNavigationBar: const ReceiverNavigationBar(
        currentItem: ReceiverNavItem.profile,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeader(user),
          const SizedBox(height: 24),
          _buildProfileForm(user),
          const SizedBox(height: 24),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildHeader(UserEntity? user) {
    final name = user?.fullName ?? '-';
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.primary,
              backgroundImage: _avatarImageProvider(user),
              child: _avatarImageProvider(user) == null
                  ? Text(
                      initial,
                      style: GoogleFonts.poppins(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            if (_isEditing)
              Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _pickPhoto,
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Penerima',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _avatarImageProvider(UserEntity? user) {
    final photo = _selectedPhoto;
    if (photo != null) return FileImage(photo);
    final photoUrl = user?.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) return null;
    return NetworkImage(photoUrl);
  }

  Widget _buildProfileForm(UserEntity? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _ProfileTextField(
              controller: _nameController,
              label: 'Nama Lengkap',
              icon: Icons.person_outline,
              enabled: _isEditing && !_isSaving,
              validator: Validators.fullName,
            ),
            const Divider(height: 24, color: AppColors.border),
            _ProfileTextField(
              controller: TextEditingController(text: user?.email ?? '-'),
              label: 'Email',
              icon: Icons.email_outlined,
              enabled: false,
            ),
            const Divider(height: 24, color: AppColors.border),
            _ProfileTextField(
              controller: _phoneController,
              label: 'Nomor HP',
              icon: Icons.phone_outlined,
              enabled: _isEditing && !_isSaving,
              keyboardType: TextInputType.phone,
              validator: Validators.phoneNumber,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _cancelEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Simpan',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _logout,
      icon: const Icon(Icons.logout, color: AppColors.error),
      label: Text(
        'Keluar',
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.error,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        icon: Icon(icon, size: 20, color: AppColors.primary),
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        disabledBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
