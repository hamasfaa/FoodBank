import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:foodbank/features/claim/domain/entities/claim_entity.dart';
import 'package:foodbank/features/claim/presentation/bloc/claim_bloc.dart';
import 'package:foodbank/features/claim/presentation/bloc/claim_event.dart';
import 'package:foodbank/features/claim/presentation/bloc/claim_state.dart';
import 'package:foodbank/injection_container.dart';

enum _ClaimFilter { all, pending, confirmed, cancelled, verified }

class DonorClaimsPage extends StatelessWidget {
  const DonorClaimsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final donorId = context.read<AuthBloc>().state.user?.uid ?? '';

    return BlocProvider(
      create: (_) => sl<ClaimBloc>()..add(LoadIncomingClaims(donorId)),
      child: _DonorClaimsView(donorId: donorId),
    );
  }
}

class _DonorClaimsView extends StatefulWidget {
  final String donorId;

  const _DonorClaimsView({required this.donorId});

  @override
  State<_DonorClaimsView> createState() => _DonorClaimsViewState();
}

class _DonorClaimsViewState extends State<_DonorClaimsView> {
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
          'Klaim Masuk',
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
            final isBusy = state.status == ClaimStatus.loading;

            return Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: claims.isEmpty
                      ? _buildEmptyState(state.claims.isEmpty)
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            context.read<ClaimBloc>().add(
                              LoadIncomingClaims(widget.donorId),
                            );
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            itemCount: claims.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final claim = claims[index];
                              return _ClaimCard(
                                claim: claim,
                                isBusy: isBusy,
                                onConfirm: () => _confirmClaim(context, claim),
                                onReject: () => _rejectClaim(context, claim),
                              );
                            },
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
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
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
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
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
                    ? Icons.inbox_outlined
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
                  ? 'Klaim dari penerima akan muncul di sini.'
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

  Future<void> _confirmClaim(BuildContext context, ClaimEntity claim) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Konfirmasi klaim?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Klaim dari ${claim.receiverName} akan dikonfirmasi. Klaim pending lain untuk makanan ini otomatis ditolak.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Batal', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Konfirmasi',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    context.read<ClaimBloc>().add(
      ConfirmClaim(
        claimId: claim.id,
        donorId: widget.donorId,
        foodId: claim.foodId,
      ),
    );
  }

  Future<void> _rejectClaim(BuildContext context, ClaimEntity claim) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Tolak klaim?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Klaim dari ${claim.receiverName} akan ditolak.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Batal', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Tolak',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    context.read<ClaimBloc>().add(
      RejectClaim(claimId: claim.id, donorId: widget.donorId),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _filterLabel(_ClaimFilter filter) {
    return switch (filter) {
      _ClaimFilter.all => 'Semua',
      _ClaimFilter.pending => 'Pending',
      _ClaimFilter.confirmed => 'Diterima',
      _ClaimFilter.cancelled => 'Ditolak',
      _ClaimFilter.verified => 'Verified',
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

class _ClaimCard extends StatelessWidget {
  final ClaimEntity claim;
  final bool isBusy;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  const _ClaimCard({
    required this.claim,
    required this.isBusy,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: Image.network(
                    claim.foodImageUrl,
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 82,
                      height: 82,
                      color: AppColors.border,
                      child: const Icon(
                        Icons.fastfood_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
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
                          _ClaimStatusBadge(status: claim.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _InfoLine(
                        icon: Icons.person_outline,
                        text: claim.receiverName,
                      ),
                      const SizedBox(height: 4),
                      _InfoLine(
                        icon: Icons.schedule_outlined,
                        text:
                            'Diklaim ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(claim.claimedAt)}',
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
          if (claim.status == 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(
                        'Tolak',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isBusy ? null : onConfirm,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        'Konfirmasi',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
              ),
            ),
        ],
      ),
    );
  }
}

class _ClaimStatusBadge extends StatelessWidget {
  final String status;

  const _ClaimStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'pending' => (const Color(0xFFF59E0B), 'Pending'),
      'confirmed' => (AppColors.success, 'Diterima'),
      'cancelled' => (AppColors.error, 'Ditolak'),
      'verified' => (AppColors.primary, 'Verified'),
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
