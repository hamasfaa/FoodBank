import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/injection_container.dart';

// ─────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────

class ClaimModel {
  final String id;
  final String foodId;
  final String donorUid;
  final String receiverUid;
  final String status; // PENDING | CONFIRMED | CANCELLED | VERIFIED
  final bool isVerifiedByAdmin;
  final DateTime? claimedAt;
  final DateTime? confirmedAt;

  const ClaimModel({
    required this.id,
    required this.foodId,
    required this.donorUid,
    required this.receiverUid,
    required this.status,
    required this.isVerifiedByAdmin,
    required this.claimedAt,
    required this.confirmedAt,
  });

  factory ClaimModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClaimModel(
      id: doc.id,
      foodId: data['foodId'] ?? '',
      donorUid: data['donorUid'] ?? '',
      receiverUid: data['receiverUid'] ?? '',
      status: data['status'] ?? 'UNKNOWN',
      isVerifiedByAdmin: data['isVerifiedByAdmin'] ?? false,
      claimedAt: (data['claimedAt'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
    );
  }

  ClaimModel copyWith({String? status, bool? isVerifiedByAdmin}) {
    return ClaimModel(
      id: id,
      foodId: foodId,
      donorUid: donorUid,
      receiverUid: receiverUid,
      status: status ?? this.status,
      isVerifiedByAdmin: isVerifiedByAdmin ?? this.isVerifiedByAdmin,
      claimedAt: claimedAt,
      confirmedAt: confirmedAt,
    );
  }
}

// ─────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────

abstract class AdminClaimsEvent {}

class FetchConfirmedClaimsEvent extends AdminClaimsEvent {}

class VerifyClaimEvent extends AdminClaimsEvent {
  final String claimId;
  VerifyClaimEvent(this.claimId);
}

// ─────────────────────────────────────────────
// States
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
// Bloc
// ─────────────────────────────────────────────

class AdminClaimsBloc extends Bloc<AdminClaimsEvent, AdminClaimsState> {
  final FirebaseFirestore _firestore;

  AdminClaimsBloc(this._firestore) : super(AdminClaimsInitial()) {
    on<FetchConfirmedClaimsEvent>(_onFetchConfirmedClaims);
    on<VerifyClaimEvent>(_onVerifyClaim);
  }

  Future<void> _onFetchConfirmedClaims(
    FetchConfirmedClaimsEvent event,
    Emitter<AdminClaimsState> emit,
  ) async {
    emit(AdminClaimsLoading());
    try {
      final snapshot = await _firestore
          .collection('claims')
          .where('status', isEqualTo: 'CONFIRMED')
          .get();
      final claims = snapshot.docs.map(ClaimModel.fromFirestore).toList();
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

    // Remove from list optimistically since verified claims leave this view.
    final updated =
        currentState.claims.where((c) => c.id != event.claimId).toList();
    emit(AdminClaimsLoaded(updated));

    try {
      await _firestore.collection('claims').doc(event.claimId).update({
        'status': 'VERIFIED',
        'isVerifiedByAdmin': true,
      });
    } catch (e) {
      emit(AdminClaimsLoaded(currentState.claims, actionError: e.toString()));
    }
  }
}

// ─────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────

class AdminClaimsPage extends StatelessWidget {
  const AdminClaimsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminClaimsBloc(sl<FirebaseFirestore>())
        ..add(FetchConfirmedClaimsEvent()),
      child: const _AdminClaimsView(),
    );
  }
}

class _AdminClaimsView extends StatelessWidget {
  const _AdminClaimsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Verify Claims'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context
                .read<AdminClaimsBloc>()
                .add(FetchConfirmedClaimsEvent()),
          ),
        ],
      ),
      body: BlocConsumer<AdminClaimsBloc, AdminClaimsState>(
        listener: (context, state) {
          if (state is AdminClaimsLoaded && state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verify failed: ${state.actionError}')),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminClaimsLoading || state is AdminClaimsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminClaimsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<AdminClaimsBloc>()
                        .add(FetchConfirmedClaimsEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is AdminClaimsLoaded) {
            if (state.claims.isEmpty) {
              return const Center(
                child: Text('No claims waiting for verification.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.claims.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final claim = state.claims[index];
                return ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text('Food: ${claim.foodId}'),
                  subtitle: Text(
                    'Donor: ${claim.donorUid}\nReceiver: ${claim.receiverUid}',
                  ),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () => context
                        .read<AdminClaimsBloc>()
                        .add(VerifyClaimEvent(claim.id)),
                    child: const Text('Verify'),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}