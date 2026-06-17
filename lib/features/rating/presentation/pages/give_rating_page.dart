import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/features/claim/domain/entities/claim_entity.dart';
import 'package:foodbank/features/rating/presentation/bloc/rating_bloc.dart';
import 'package:foodbank/features/rating/presentation/bloc/rating_event.dart';
import 'package:foodbank/features/rating/presentation/bloc/rating_state.dart';
import 'package:foodbank/injection_container.dart';

class GiveRatingPage extends StatelessWidget {
  final ClaimEntity claim;

  const GiveRatingPage({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RatingBloc>(),
      child: _GiveRatingView(claim: claim),
    );
  }
}

class _GiveRatingView extends StatefulWidget {
  final ClaimEntity claim;

  const _GiveRatingView({required this.claim});

  @override
  State<_GiveRatingView> createState() => _GiveRatingViewState();
}

class _GiveRatingViewState extends State<_GiveRatingView> {
  int _score = 0;
  final _commentController = TextEditingController();
  XFile? _proofImage;
  bool _uploading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1080,
    );
    if (picked != null) setState(() => _proofImage = picked);
  }

  Future<String> _uploadProof() async {
    const uuid = Uuid();
    final ref = FirebaseStorage.instance
        .ref()
        .child('ratings/${uuid.v4()}/proof.jpg');
    await ref.putFile(File(_proofImage!.path));
    return await ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (_score == 0) {
      _showSnack('Pilih bintang terlebih dahulu', isError: true);
      return;
    }
    if (_proofImage == null) {
      _showSnack('Upload foto bukti pengambilan terlebih dahulu', isError: true);
      return;
    }

    setState(() => _uploading = true);
    try {
      final photoUrl = await _uploadProof();
      if (!mounted) return;
      context.read<RatingBloc>().add(SubmitRating(
            claimId: widget.claim.id,
            donorId: widget.claim.donorId,
            receiverId: widget.claim.receiverId,
            score: _score,
            comment: _commentController.text.trim(),
            photoUrl: photoUrl,
          ));
    } catch (e) {
      if (mounted) {
        _showSnack('Gagal mengupload foto bukti', isError: true);
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Beri Rating & Bukti',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: BlocListener<RatingBloc, RatingState>(
        listener: (context, state) {
          if (state.status == RatingStatus.success) {
            setState(() => _uploading = false);
            _showSnack('Rating dikirim! Menunggu verifikasi admin.');
            Navigator.of(context).pop();
          }
          if (state.status == RatingStatus.failure) {
            setState(() => _uploading = false);
            _showSnack(
              state.errorMessage ?? 'Gagal mengirim rating',
              isError: true,
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFoodInfo(),
              const SizedBox(height: 28),
              _buildProofSection(),
              const SizedBox(height: 28),
              _buildStarSection(),
              const SizedBox(height: 28),
              _buildCommentSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.claim.foodImageUrl.isNotEmpty
                ? Image.network(
                    widget.claim.foodImageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, e) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.claim.foodTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Donor: ${widget.claim.donorName}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.border,
      child: const Icon(Icons.fastfood_outlined, color: AppColors.textSecondary),
    );
  }

  Widget _buildProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Foto Bukti Pengambilan',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Wajib',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Foto sebagai bukti bahwa kamu sudah mengambil makanan. Akan diverifikasi oleh admin.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        if (_proofImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_proofImage!.path),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text(
                    'Ambil Ulang',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(
                    'Dari Galeri',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickImage(ImageSource.camera),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            color: AppColors.primary, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Kamera',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            color: AppColors.textSecondary, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Galeri',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nilai Donor',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Seberapa puas kamu dengan donasi ini?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final star = index + 1;
            return GestureDetector(
              onTap: () => setState(() => _score = star),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  star <= _score ? Icons.star_rounded : Icons.star_outline_rounded,
                  color:
                      star <= _score ? const Color(0xFFF59E0B) : AppColors.border,
                  size: 48,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _score == 0
                ? 'Belum dipilih'
                : ['', 'Sangat Buruk', 'Buruk', 'Cukup', 'Baik', 'Sangat Baik'][_score],
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _score == 0 ? AppColors.textSecondary : const Color(0xFFF59E0B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Komentar (opsional)',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _commentController,
          maxLines: 4,
          maxLength: 300,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tulis kesanmu tentang donasi ini...',
            hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
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
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<RatingBloc, RatingState>(
      builder: (context, state) {
        final isLoading = state.status == RatingStatus.loading || _uploading;
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Kirim Rating',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
