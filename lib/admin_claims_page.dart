import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/injection_container.dart';
import 'package:intl/intl.dart';

class ClaimModel {
  final String id;
  final String foodId;
  final String foodTitle;
  final String foodImageUrl;
  final String donorId;
  final String donorName;
  final String receiverId;
  final String receiverName;
  final String status; // pending | confirmed | cancelled | verified
  final bool isVerifiedByAdmin;
  final String? proofPhotoUrl;
  final DateTime? claimedAt;
  final DateTime? confirmedAt;

  const ClaimModel({
    required this.id,
    required this.foodId,
    required this.foodTitle,
    required this.foodImageUrl,
    required this.donorId,
    required this.donorName,
    required this.receiverId,
    required this.receiverName,
    required this.status,
    required this.isVerifiedByAdmin,
    this.proofPhotoUrl,
    this.claimedAt,
    this.confirmedAt,
  });

  bool get hasProofPhoto => proofPhotoUrl?.trim().isNotEmpty ?? false;

  factory ClaimModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClaimModel(
      id: doc.id,
      foodId: data['foodId'] as String? ?? '',
      foodTitle: data['foodTitle'] as String? ?? '',
      foodImageUrl: data['foodImageUrl'] as String? ?? '',
      donorId: data['donorId'] as String? ?? '',
      donorName: data['donorName'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      receiverName: data['receiverName'] as String? ?? '',
      status: data['status'] as String? ?? 'unknown',
      isVerifiedByAdmin: data['isVerifiedByAdmin'] as bool? ?? false,
      proofPhotoUrl: data['proofPhotoUrl'] as String?,
      claimedAt: data['claimedAt'] != null
          ? (data['claimedAt'] as Timestamp).toDate()
          : null,
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

abstract class AdminClaimsEvent {}

class FetchClaimsByStatusEvent extends AdminClaimsEvent {
  final String status;

  FetchClaimsByStatusEvent(this.status);
}

class VerifyClaimEvent extends AdminClaimsEvent {
  final String claimId;

  VerifyClaimEvent(this.claimId);
}

abstract class AdminClaimsState {}

class AdminClaimsInitial extends AdminClaimsState {}

class AdminClaimsLoading extends AdminClaimsState {}

class AdminClaimsLoaded extends AdminClaimsState {
  final List<ClaimModel> claims;
  final String? actionError;

  AdminClaimsLoaded(this.claims, {this.actionError});
}

class AdminClaimsError extends AdminClaimsState {
  final String message;

  AdminClaimsError(this.message);
}

class AdminClaimsBloc extends Bloc<AdminClaimsEvent, AdminClaimsState> {
  final FirebaseFirestore _firestore;

  AdminClaimsBloc(this._firestore) : super(AdminClaimsInitial()) {
    on<FetchClaimsByStatusEvent>(_onFetchClaimsByStatus);
    on<VerifyClaimEvent>(_onVerifyClaim);
  }

  Future<void> _onFetchClaimsByStatus(
    FetchClaimsByStatusEvent event,
    Emitter<AdminClaimsState> emit,
  ) async {
    emit(AdminClaimsLoading());
    try {
      final snapshot = await _firestore
          .collection('claims')
          .where('status', isEqualTo: event.status)
          .get();
      final claims = snapshot.docs.map(ClaimModel.fromFirestore).toList()
        ..sort((a, b) {
          final aDate = a.claimedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.claimedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      emit(AdminClaimsLoaded(claims));
    } catch (e) {
      emit(AdminClaimsError(e.toString()));
    }
  }

  Future<void> _onVerifyClaim(
    VerifyClaimEvent event,
    Emitter<AdminClaimsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AdminClaimsLoaded) return;

    ClaimModel? claimToVerify;
    for (final claim in currentState.claims) {
      if (claim.id == event.claimId) {
        claimToVerify = claim;
        break;
      }
    }
    if (claimToVerify == null) return;

    if (!claimToVerify.hasProofPhoto) {
      emit(
        AdminClaimsLoaded(
          currentState.claims,
          actionError: 'Klaim belum memiliki foto bukti.',
        ),
      );
      return;
    }

    final updated = currentState.claims
        .where((claim) => claim.id != event.claimId)
        .toList();
    emit(AdminClaimsLoaded(updated));

    try {
      final claimRef = _firestore.collection('claims').doc(event.claimId);
      final latestDoc = await claimRef.get();

      if (!latestDoc.exists) {
        throw Exception('Klaim tidak ditemukan.');
      }

      final latestClaim = ClaimModel.fromFirestore(latestDoc);
      if (latestClaim.status != 'confirmed') {
        throw Exception(
          'Hanya klaim yang sudah diterima donor yang bisa diverifikasi.',
        );
      }
      if (!latestClaim.hasProofPhoto) {
        throw Exception('Klaim belum memiliki foto bukti.');
      }

      final batch = _firestore.batch();
      batch.update(claimRef, {
        'status': 'verified',
        'isVerifiedByAdmin': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      batch.set(_firestore.collection('notifications').doc(), {
        'recipientId': latestClaim.receiverId,
        'senderId': 'admin',
        'senderName': 'Admin',
        'type': 'claim_verified',
        'title': 'Klaim Terverifikasi',
        'body':
            'Admin sudah memverifikasi bukti pengambilan ${latestClaim.foodTitle}. Sekarang kamu bisa memberi rating.',
        'data': {
          'claimId': latestClaim.id,
          'foodId': latestClaim.foodId,
          'donorId': latestClaim.donorId,
        },
        'deliveredAt': null,
        'readAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      emit(AdminClaimsLoaded(currentState.claims, actionError: e.toString()));
    }
  }
}

class AdminClaimsPage extends StatelessWidget {
  const AdminClaimsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Admin - Claims'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Siap Verify'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BlocProvider(
              create: (_) =>
                  AdminClaimsBloc(sl<FirebaseFirestore>())
                    ..add(FetchClaimsByStatusEvent('pending')),
              child: const _AdminClaimsListView(
                status: 'pending',
                emptyMessage: 'Belum ada klaim pending.',
                showVerifyButton: false,
              ),
            ),
            BlocProvider(
              create: (_) =>
                  AdminClaimsBloc(sl<FirebaseFirestore>())
                    ..add(FetchClaimsByStatusEvent('confirmed')),
              child: const _AdminClaimsListView(
                status: 'confirmed',
                emptyMessage: 'Belum ada klaim yang menunggu verifikasi.',
                showVerifyButton: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminClaimsListView extends StatelessWidget {
  final String status;
  final String emptyMessage;
  final bool showVerifyButton;

  const _AdminClaimsListView({
    required this.status,
    required this.emptyMessage,
    required this.showVerifyButton,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminClaimsBloc, AdminClaimsState>(
      listener: (context, state) {
        if (state is AdminClaimsLoaded && state.actionError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verify gagal: ${state.actionError}')),
          );
        }
      },
      builder: (context, state) {
        if (state is AdminClaimsLoading || state is AdminClaimsInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AdminClaimsError) {
          return _AdminClaimsMessage(
            icon: Icons.error_outline,
            message: state.message,
            actionLabel: 'Coba Lagi',
            onAction: () => context.read<AdminClaimsBloc>().add(
              FetchClaimsByStatusEvent(status),
            ),
          );
        }

        if (state is AdminClaimsLoaded) {
          return RefreshIndicator(
            onRefresh: () async => context.read<AdminClaimsBloc>().add(
              FetchClaimsByStatusEvent(status),
            ),
            child: state.claims.isEmpty
                ? _AdminClaimsMessage(
                    icon: Icons.inbox_outlined,
                    message: emptyMessage,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.claims.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final claim = state.claims[index];
                      return _AdminClaimCard(
                        claim: claim,
                        showVerifyButton: showVerifyButton,
                        onVerify: claim.hasProofPhoto
                            ? () => context.read<AdminClaimsBloc>().add(
                                VerifyClaimEvent(claim.id),
                              )
                            : null,
                      );
                    },
                  ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _AdminClaimCard extends StatelessWidget {
  final ClaimModel claim;
  final bool showVerifyButton;
  final VoidCallback? onVerify;

  const _AdminClaimCard({
    required this.claim,
    required this.showVerifyButton,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ClaimImage(url: claim.foodImageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              claim.foodTitle.isNotEmpty
                                  ? claim.foodTitle
                                  : '(food: ${claim.foodId})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ClaimStatusChip(status: claim.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoLine(
                        icon: Icons.volunteer_activism_outlined,
                        text: 'Donor: ${claim.donorName}',
                      ),
                      const SizedBox(height: 4),
                      _InfoLine(
                        icon: Icons.person_outline,
                        text: 'Penerima: ${claim.receiverName}',
                      ),
                      if (claim.claimedAt != null) ...[
                        const SizedBox(height: 4),
                        _InfoLine(
                          icon: Icons.schedule_outlined,
                          text: 'Diklaim ${_formatDate(claim.claimedAt!)}',
                        ),
                      ],
                      if (claim.confirmedAt != null) ...[
                        const SizedBox(height: 4),
                        _InfoLine(
                          icon: Icons.check_circle_outline,
                          text:
                              'Diterima donor ${_formatDate(claim.confirmedAt!)}',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (showVerifyButton) ...[
              const SizedBox(height: 12),
              _ProofSection(claim: claim),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onVerify,
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: const Text('Verify Klaim'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
  }
}

class _ProofSection extends StatelessWidget {
  final ClaimModel claim;

  const _ProofSection({required this.claim});

  @override
  Widget build(BuildContext context) {
    if (!claim.hasProofPhoto) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.hourglass_top_outlined,
              size: 18,
              color: Color(0xFFF59E0B),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Menunggu penerima upload foto bukti.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final proofUrl = claim.proofPhotoUrl!;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showProofDialog(context, proofUrl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                proofUrl,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 54,
                  height: 54,
                  color: AppColors.border,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto bukti tersedia',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ketuk untuk melihat foto sebelum verify.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_full, size: 18, color: AppColors.success),
          ],
        ),
      ),
    );
  }

  void _showProofDialog(BuildContext context, String proofUrl) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 520),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  proofUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 240,
                    child: Center(child: Text('Gagal memuat foto bukti.')),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimImage extends StatelessWidget {
  final String url;

  const _ClaimImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url.isNotEmpty
          ? Image.network(
              url,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.border,
      child: const Icon(
        Icons.fastfood_outlined,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ClaimStatusChip extends StatelessWidget {
  final String status;

  const _ClaimStatusChip({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
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

class _AdminClaimsMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AdminClaimsMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: 320,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
