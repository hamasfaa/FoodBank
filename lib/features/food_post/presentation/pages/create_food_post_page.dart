import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:foodbank/features/food_post/domain/entities/food_location_entity.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_bloc.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_event.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_state.dart';
import 'location_picker_page.dart';

class CreateFoodPostPage extends StatefulWidget {
  const CreateFoodPostPage({super.key});

  @override
  State<CreateFoodPostPage> createState() => _CreateFoodPostPageState();
}

class _CreateFoodPostPageState extends State<CreateFoodPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();

  final _titleFocus = FocusNode();
  final _descFocus = FocusNode();
  final _quantityFocus = FocusNode();

  final List<File> _selectedImages = [];
  static const int _maxImages = 5;
  DateTime? _expiredAt;
  FoodLocationEntity? _selectedLocation;
  bool _autoValidate = false;

  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    Navigator.of(context).pop();
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1024,
      );
      if (picked != null && _selectedImages.length < _maxImages) {
        setState(() => _selectedImages.add(File(picked.path)));
      }
    } catch (e) {
      if (mounted) _showError('Gagal membuka kamera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    Navigator.of(context).pop();
    try {
      final remaining = _maxImages - _selectedImages.length;
      final picked = await _imagePicker.pickMultiImage(
        imageQuality: 75,
        maxWidth: 1024,
        limit: remaining,
      );
      if (picked.isNotEmpty) {
        setState(() {
          for (final xfile in picked) {
            if (_selectedImages.length < _maxImages) {
              _selectedImages.add(File(xfile.path));
            }
          }
        });
      }
    } catch (e) {
      if (mounted) _showError('Gagal memilih gambar: $e');
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tambah Foto',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_selectedImages.length}/$_maxImages foto dipilih',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: Text('Kamera', style: GoogleFonts.inter(fontSize: 15)),
              onTap: _pickFromCamera,
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: Text('Galeri', style: GoogleFonts.inter(fontSize: 15)),
              onTap: _pickFromGallery,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiredAt ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiredAt = picked);
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<FoodLocationEntity>(
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (result != null) setState(() => _selectedLocation = result);
  }

  void _submit() {
    setState(() => _autoValidate = true);

    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      _showError('Pilih minimal 1 foto makanan');
      return;
    }
    if (_expiredAt == null) {
      _showError('Pilih tanggal kadaluarsa');
      return;
    }
    if (_selectedLocation == null) {
      _showError('Pilih lokasi pengambilan');
      return;
    }

    final authState = context.read<AuthBloc>().state;
    final user = authState.user;
    if (user == null) return;

    context.read<FoodPostBloc>().add(
      CreateFoodPostSubmitted(
        donorId: user.uid,
        donorName: user.fullName,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        quantity: double.parse(_quantityController.text.trim()),
        expiredAt: _expiredAt!,
        location: _selectedLocation!,
        images: _selectedImages,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FoodPostBloc, FoodPostState>(
      listener: (context, state) {
        if (state.status == FoodPostStatus.failure) {
          _showError(state.errorMessage ?? 'Terjadi kesalahan');
        } else if (state.status == FoodPostStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Postingan berhasil dibuat!',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Buat Postingan Donasi',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<FoodPostBloc, FoodPostState>(
      builder: (context, state) {
        final isLoading = state.status == FoodPostStatus.loading;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePicker(),
                const SizedBox(height: 20),
                _buildLabel('Judul Makanan'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _titleController,
                  focusNode: _titleFocus,
                  nextFocus: _descFocus,
                  hint: 'Cth: Nasi Putih Sisa Katering',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Judul wajib diisi';
                    if (v.trim().length < 5) return 'Judul minimal 5 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildLabel('Deskripsi'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _descriptionController,
                  focusNode: _descFocus,
                  hint: 'Ceritakan kondisi makanan, porsi, dll.',
                  maxLines: 3,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Deskripsi wajib diisi';
                    if (v.trim().length < 10)
                      return 'Deskripsi minimal 10 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildLabel('Kuantitas (gram)'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _quantityController,
                  focusNode: _quantityFocus,
                  hint: 'Cth: 500',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Kuantitas wajib diisi';
                    final val = double.tryParse(v.trim());
                    if (val == null || val <= 0)
                      return 'Masukkan nilai yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildLabel('Tanggal Kadaluarsa'),
                const SizedBox(height: 6),
                _buildDatePicker(),
                const SizedBox(height: 16),
                _buildLabel('Lokasi Pengambilan'),
                const SizedBox(height: 6),
                _buildLocationPicker(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Posting Donasi',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Foto Makanan',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${_selectedImages.length}/$_maxImages',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._selectedImages.asMap().entries.map(
                (entry) => _buildImageThumb(entry.value, entry.key),
              ),
              if (_selectedImages.length < _maxImages) _buildAddImageButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumb(File file, int index) {
    return Container(
      width: 110,
      height: 110,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(file, width: 110, height: 110, fit: BoxFit.cover),
          ),
          if (index == 0)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Utama',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedImages.isEmpty
                ? AppColors.primary
                : AppColors.border,
            width: _selectedImages.isEmpty ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 28,
              color: _selectedImages.isEmpty
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              _selectedImages.isEmpty ? 'Tambah\nFoto' : 'Tambah',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _selectedImages.isEmpty
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: nextFocus != null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          focusNode.unfocus();
        }
      },
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _expiredAt != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: _expiredAt != null
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              _expiredAt != null
                  ? DateFormat('dd MMMM yyyy', 'id_ID').format(_expiredAt!)
                  : 'Pilih tanggal kadaluarsa',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _expiredAt != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPicker() {
    return GestureDetector(
      onTap: _pickLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedLocation != null
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 18,
              color: _selectedLocation != null
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedLocation?.address ??
                    'Ketuk untuk memilih lokasi di peta',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _selectedLocation != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
