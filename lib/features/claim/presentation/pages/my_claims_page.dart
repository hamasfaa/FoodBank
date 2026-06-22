import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/core/widgets/receiver_navigation_bar.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:foodbank/features/claim/domain/entities/claim_entity.dart';
import 'package:foodbank/features/claim/presentation/bloc/claim_bloc.dart';
import 'package:foodbank/features/claim/presentation/bloc/claim_event.dart';
import 'package:foodbank/features/claim/presentation/bloc/claim_state.dart';
import 'package:foodbank/features/food_post/data/models/food_post_model.dart';
import 'package:foodbank/features/food_post/presentation/pages/food_detail_page.dart';
import 'package:foodbank/features/rating/presentation/pages/give_rating_page.dart';
import 'package:foodbank/injection_container.dart';

enum _ClaimFilter { all, pending, confirmed, cancelled, verified }

class MyClaimsPage extends StatelessWidget {
  const MyClaimsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    return BlocProvider(
      create: (_) => sl<ClaimBloc>()..add(LoadMyClaims(user?.uid ?? '')),
      child: const _MyClaimsView(),
    );
  }
}

class _MyClaimsView extends StatefulWidget {
  const _MyClaimsView();

  @override
  State<_MyClaimsView> createState() => _MyClaimsViewState();
}

class _MyClaimsViewState extends State<_MyClaimsView> {
  _ClaimFilter _filter = _ClaimFilter.all;

  List<ClaimEntity> _filtered(List<ClaimEntity> claims) {
    return claims.where((claim) {
      return switch (_filter) {
        _ClaimFilter.all => true,
        _ClaimFilter.pending => claim.status == 'pending',
        _ClaimFilter.confirmed => claim.status == 'confirmed',
        _ClaimFilter.cancelled => claim.status == 'cancelled',
        _ClaimFilter.verified => claim.status == 'verified',
      };
    }).toList();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Klaimku',
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
      bottomNavigationBar: const ReceiverNavigationBar(
        currentItem: ReceiverNavItem.claims,
      ),
      body: BlocListener<ClaimBloc, ClaimState>(
        listener: (context, state) {
          if (state.status == ClaimStatus.failure) {
            _showSnack(
              state.errorMessage ?? 'Terjadi kesalahan',
              isError: true,
            );
          } else if (state.status == ClaimStatus.success &&
              state.successMessage != null) {
            _showSnack(state.successMessage!);
          }
        },
        child: BlocBuilder<ClaimBloc, ClaimState>(
          builder: (context, state) {
            if (state.status == ClaimStatus.loading && state.claims.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final claims = _filtered(state.claims);

            return Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: claims.isEmpty
                      ? _buildEmptyState(state.claims.isEmpty)
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            final user =
                                context.read<AuthBloc>().state.user;
                            context
                                .read<ClaimBloc>()
                                .add(LoadMyClaims(user?.uid ?? ''));
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            itemCount: claims.length,
                            separatorBuilder: (_, i) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) =>
                                _ClaimCard(claim: claims[i]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _ClaimFilter.values.length,
          separatorBuilder: (_, i) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            final filter = _ClaimFilter.values[index];
            final selected = filter == _filter;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _filter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _filterIcon(filter),
                        size: 18,
                        color: selected ? Colors.white : _filterColor(filter),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _filterLabel(filter),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noClaimsAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                noClaimsAtAll
                    ? Icons.receipt_long_outlined
                    : Icons.filter_alt_off_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              noClaimsAtAll ? 'Belum Ada Klaim' : 'Tidak Ada Hasil',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noClaimsAtAll
                  ? 'Kamu belum mengklaim makanan apapun.'
                  : 'Coba pilih filter status lain.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(_ClaimFilter filter) {
    return switch (filter) {
      _ClaimFilter.all => 'Semua',
      _ClaimFilter.pending => 'Menunggu',
      _ClaimFilter.confirmed => 'Dikonfirmasi',
      _ClaimFilter.cancelled => 'Dibatalkan',
      _ClaimFilter.verified => 'Terverifikasi',
    };
  }

  IconData _filterIcon(_ClaimFilter filter) {
    return switch (filter) {
      _ClaimFilter.all => Icons.tune_outlined,
      _ClaimFilter.pending => Icons.hourglass_empty_outlined,
      _ClaimFilter.confirmed => Icons.check_circle_outline,
      _ClaimFilter.cancelled => Icons.cancel_outlined,
      _ClaimFilter.verified => Icons.verified_outlined,
    };
  }

  Color _filterColor(_ClaimFilter filter) {
    return switch (filter) {
      _ClaimFilter.all => AppColors.textSecondary,
      _ClaimFilter.pending => const Color(0xFFF59E0B),
      _ClaimFilter.confirmed => AppColors.success,
      _ClaimFilter.cancelled => AppColors.error,
      _ClaimFilter.verified => AppColors.primary,
    };
  }
}

class _ClaimCard extends StatefulWidget {
  final ClaimEntity claim;

  const _ClaimCard({required this.claim});

  @override
  State<_ClaimCard> createState() => _ClaimCardState();
}

class _ClaimCardState extends State<_ClaimCard> {
  bool _loadingDetail = false;
  bool _hasRated = false;
  bool _checkingRating = false;
  bool _uploadingProof = false;

  @override
  void initState() {
    super.initState();
    if (widget.claim.status == 'verified') {
      _checkExistingRating();
    }
  }

  Future<void> _checkExistingRating() async {
    setState(() => _checkingRating = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('ratings')
          .where('claimId', isEqualTo: widget.claim.id)
          .limit(1)
          .get();
      if (mounted) setState(() => _hasRated = query.docs.isNotEmpty);
    } catch (_) {
      // diam-diam gagal, tombol tetap ditampilkan
    } finally {
      if (mounted) setState(() => _checkingRating = false);
    }
  }

  Future<void> _pickAndUploadProof(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingProof = true);
    try {
      const uuid = Uuid();
      final ref = FirebaseStorage.instance
          .ref()
          .child('claims/${widget.claim.id}/${uuid.v4()}_proof.jpg');
      await ref.putFile(File(picked.path));
      final photoUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('claims')
          .doc(widget.claim.id)
          .update({'proofPhotoUrl': photoUrl});

      if (mounted) {
        final user = context.read<AuthBloc>().state.user;
        context.read<ClaimBloc>().add(LoadMyClaims(user?.uid ?? ''));
      }
    } catch (e) {
      if (mounted) _showError('Gagal mengupload foto bukti');
    } finally {
      if (mounted) setState(() => _uploadingProof = false);
    }
  }

  void _showProofSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Pilih Sumber Foto',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: Text('Kamera', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadProof(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.textSecondary),
                title: Text('Galeri', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadProof(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail() async {
    if (_loadingDetail) return;
    setState(() => _loadingDetail = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('food_posts')
          .doc(widget.claim.foodId)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        _showError('Data makanan tidak ditemukan');
        return;
      }

      final post = FoodPostModel.fromFirestore(doc);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FoodDetailPage(post: post, hideClaimButton: true),
        ),
      );
    } catch (e) {
      if (mounted) _showError('Gagal memuat detail makanan');
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
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
    final claim = widget.claim;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: claim.foodImageUrl.isNotEmpty
                      ? Image.network(
                          claim.foodImageUrl,
                          width: 82,
                          height: 82,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, e) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              claim.foodTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusBadge(status: claim.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _InfoLine(
                        icon: Icons.person_outline,
                        text: 'Donor: ${claim.donorName}',
                      ),
                      const SizedBox(height: 4),
                      _InfoLine(
                        icon: Icons.schedule_outlined,
                        text: DateFormat('dd MMM yyyy, HH:mm')
                            .format(claim.claimedAt),
                      ),
                      if (claim.confirmedAt != null) ...[
                        const SizedBox(height: 4),
                        _InfoLine(
                          icon: Icons.check_circle_outline,
                          text:
                              'Dikonfirmasi ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(claim.confirmedAt!)}',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildActions(context, claim),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 82,
      height: 82,
      color: AppColors.border,
      child: const Icon(Icons.fastfood_outlined, color: AppColors.textSecondary),
    );
  }

  Widget _buildActions(BuildContext context, ClaimEntity claim) {
    if (claim.status == 'pending') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadingDetail ? null : _openDetail,
                icon: _loadingDetail
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.location_on_outlined, size: 18),
                label: Text(
                  'Lihat Detail & Lokasi',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmCancel(context),
                icon: const Icon(Icons.close, size: 18),
                label: Text(
                  'Batalkan Klaim',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (claim.status == 'confirmed') {
      final hasProof = claim.proofPhotoUrl != null &&
          claim.proofPhotoUrl!.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: hasProof
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_outlined,
                        size: 15, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Foto bukti dikirim · menunggu verifikasi admin',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF59E0B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loadingDetail ? null : _openDetail,
                      icon: _loadingDetail
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2),
                            )
                          : const Icon(Icons.location_on_outlined, size: 18),
                      label: Text(
                        'Lihat Detail & Lokasi',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _uploadingProof ? null : _showProofSourcePicker,
                      icon: _uploadingProof
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined, size: 18),
                      label: Text(
                        'Upload Foto Bukti Pengambilan',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
      );
    }

    if (claim.status == 'verified') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadingDetail ? null : _openDetail,
                    icon: _loadingDetail
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.info_outline, size: 18),
                    label: Text(
                      'Detail',
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
                if (!_hasRated) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _checkingRating
                          ? null
                          : () => Navigator.of(context)
                              .push(MaterialPageRoute(
                                  builder: (_) => GiveRatingPage(claim: claim)))
                              .then((_) => _checkExistingRating()),
                      icon: _checkingRating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.star_outline, size: 18),
                      label: Text(
                        'Beri Rating',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_hasRated) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Rating sudah diberikan',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Batalkan Klaim?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Apakah kamu yakin ingin membatalkan klaim "${widget.claim.foodTitle}"?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Tidak',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ClaimBloc>().add(CancelClaim(widget.claim.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Batalkan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'pending' => (const Color(0xFFF59E0B), 'Menunggu'),
      'confirmed' => (AppColors.success, 'Dikonfirmasi'),
      'cancelled' => (AppColors.textSecondary, 'Dibatalkan'),
      'verified' => (AppColors.primary, 'Terverifikasi'),
      _ => (AppColors.textSecondary, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
