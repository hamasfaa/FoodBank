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
  final String foodTitle;
  final String foodImageUrl;
  final String donorId;
  final String donorName;
  final String receiverId;
  final String receiverName;
  final String status; // pending | confirmed | cancelled | verified
  final bool isVerifiedByAdmin;
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
    this.claimedAt,
    this.confirmedAt,
  });

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
      claimedAt: data['claimedAt'] != null
          ? (data['claimedAt'] as Timestamp).toDate()
          : null,
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
    );
  }

  ClaimModel copyWith({String? status, bool? isVerifiedByAdmin}) {
    return ClaimModel(
      id: id,
      foodId: foodId,
      foodTitle: foodTitle,
      foodImageUrl: foodImageUrl,
      donorId: donorId,
      donorName: donorName,
      receiverId: receiverId,
      receiverName: receiverName,
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

class FetchClaimsByStatusEvent extends AdminClaimsEvent {
  final String status;
  FetchClaimsByStatusEvent(this.status);
}

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
  String _lastStatus = 'pending';

  AdminClaimsBloc(this._firestore) : super(AdminClaimsInitial()) {
    on<FetchClaimsByStatusEvent>(_onFetchClaimsByStatus);
    on<VerifyClaimEvent>(_onVerifyClaim);
  }

  Future<void> _onFetchClaimsByStatus(
    FetchClaimsByStatusEvent event,
    Emitter<AdminClaimsState> emit,
  ) async {
    _lastStatus = event.status;
    emit(AdminClaimsLoading());
    try {
      final snapshot = await _firestore
          .collection('claims')
          .where('status', isEqualTo: event.status)
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
        'status': 'verified',
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin — Claims'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Awaiting Verification'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BlocProvider(
              create: (_) => AdminClaimsBloc(sl<FirebaseFirestore>())
                ..add(FetchClaimsByStatusEvent('pending')),
              child: const _AdminClaimsListView(
                status: 'pending',
                emptyMessage: 'No pending claims.',
                showVerifyButton: false,
              ),
            ),
            BlocProvider(
              create: (_) => AdminClaimsBloc(sl<FirebaseFirestore>())
                ..add(FetchClaimsByStatusEvent('confirmed')),
              child: const _AdminClaimsListView(
                status: 'confirmed',
                emptyMessage: 'No claims waiting for verification.',
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
            SnackBar(content: Text('Verify failed: ${state.actionError}')),
          );
        }
      },
      builder: (context, state) {
        if (state is AdminClaimsLoading || state is AdminClaimsInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AdminClaimsError) {
          return ListView(
            children: [
              SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(state.message, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context
                            .read<AdminClaimsBloc>()
                            .add(FetchClaimsByStatusEvent(status)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        if (state is AdminClaimsLoaded) {
          return RefreshIndicator(
            onRefresh: () async => context
                .read<AdminClaimsBloc>()
                .add(FetchClaimsByStatusEvent(status)),
            child: state.claims.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: 300,
                        child: Center(child: Text(emptyMessage)),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.claims.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final claim = state.claims[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              claim.foodImageUrl.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(claim.foodImageUrl),
                                    )
                                  : const CircleAvatar(
                                      child:
                                          Icon(Icons.local_shipping_outlined),
                                    ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      claim.foodTitle.isNotEmpty
                                          ? claim.foodTitle
                                          : '(food: ${claim.foodId})',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Donor: ${claim.donorName}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Receiver: ${claim.receiverName}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (showVerifyButton) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: ElevatedButton(
                                    onPressed: () => context
                                        .read<AdminClaimsBloc>()
                                        .add(VerifyClaimEvent(claim.id)),
                                    child: const Text('Verify',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
