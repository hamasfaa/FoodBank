import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/injection_container.dart';

// ─────────────────────────────────────────────
// Stats — Events / States / Bloc
// ─────────────────────────────────────────────

abstract class AdminStatsEvent {}

class FetchStatsEvent extends AdminStatsEvent {}

abstract class AdminStatsState {}

class AdminStatsInitial extends AdminStatsState {}

class AdminStatsLoading extends AdminStatsState {}

class AdminStatsLoaded extends AdminStatsState {
  final int totalUsers;
  final int totalPosts;
  final int pendingClaims;
  AdminStatsLoaded({
    required this.totalUsers,
    required this.totalPosts,
    required this.pendingClaims,
  });
}

class AdminStatsError extends AdminStatsState {
  final String message;
  AdminStatsError(this.message);
}

class AdminStatsBloc extends Bloc<AdminStatsEvent, AdminStatsState> {
  final FirebaseFirestore _firestore;

  AdminStatsBloc(this._firestore) : super(AdminStatsInitial()) {
    on<FetchStatsEvent>(_onFetchStats);
  }

  Future<void> _onFetchStats(
    FetchStatsEvent event,
    Emitter<AdminStatsState> emit,
  ) async {
    emit(AdminStatsLoading());
    try {
      // count() aggregation queries avoid pulling full documents.
      final usersCount =
          (await _firestore.collection('users').count().get()).count ?? 0;
      final postsCount =
          (await _firestore.collection('foods').count().get()).count ?? 0;
      final pendingClaimsCount = (await _firestore
                  .collection('claims')
                  .where('status', isEqualTo: 'PENDING')
                  .count()
                  .get())
              .count ??
          0;

      emit(AdminStatsLoaded(
        totalUsers: usersCount,
        totalPosts: postsCount,
        pendingClaims: pendingClaimsCount,
      ));
    } catch (e) {
      emit(AdminStatsError(e.toString()));
    }
  }
}

// ─────────────────────────────────────────────
// Ratings — Model / Events / States / Bloc
// ─────────────────────────────────────────────

class RatingModel {
  final String id;
  final String claimId;
  final String donorUid;
  final String receiverUid;
  final int score;
  final String comment;
  final DateTime? createdAt;

  const RatingModel({
    required this.id,
    required this.claimId,
    required this.donorUid,
    required this.receiverUid,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RatingModel(
      id: doc.id,
      claimId: data['claimId'] ?? '',
      donorUid: data['donorUid'] ?? '',
      receiverUid: data['receiverUid'] ?? '',
      score: data['score'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

abstract class AdminRatingsEvent {}

class FetchRatingsEvent extends AdminRatingsEvent {}

abstract class AdminRatingsState {}

class AdminRatingsInitial extends AdminRatingsState {}

class AdminRatingsLoading extends AdminRatingsState {}

class AdminRatingsLoaded extends AdminRatingsState {
  final List<RatingModel> ratings;
  AdminRatingsLoaded(this.ratings);
}

class AdminRatingsError extends AdminRatingsState {
  final String message;
  AdminRatingsError(this.message);
}

class AdminRatingsBloc extends Bloc<AdminRatingsEvent, AdminRatingsState> {
  final FirebaseFirestore _firestore;

  AdminRatingsBloc(this._firestore) : super(AdminRatingsInitial()) {
    on<FetchRatingsEvent>(_onFetchRatings);
  }

  Future<void> _onFetchRatings(
    FetchRatingsEvent event,
    Emitter<AdminRatingsState> emit,
  ) async {
    emit(AdminRatingsLoading());
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .orderBy('createdAt', descending: true)
          .get();
      final ratings = snapshot.docs.map(RatingModel.fromFirestore).toList();
      emit(AdminRatingsLoaded(ratings));
    } catch (e) {
      emit(AdminRatingsError(e.toString()));
    }
  }
}

// ─────────────────────────────────────────────
// Page — Dashboard with Stats + Ratings tabs
// ─────────────────────────────────────────────

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              AdminStatsBloc(sl<FirebaseFirestore>())..add(FetchStatsEvent()),
        ),
        BlocProvider(
          create: (_) => AdminRatingsBloc(sl<FirebaseFirestore>())
            ..add(FetchRatingsEvent()),
        ),
      ],
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Ratings'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _StatsTab(),
            _RatingsTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stats tab
// ─────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminStatsBloc, AdminStatsState>(
      builder: (context, state) {
        if (state is AdminStatsLoading || state is AdminStatsInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AdminStatsError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      context.read<AdminStatsBloc>().add(FetchStatsEvent()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is AdminStatsLoaded) {
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<AdminStatsBloc>().add(FetchStatsEvent()),
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _StatCard(
                  icon: Icons.people_outline,
                  label: 'Total Users',
                  value: state.totalUsers.toString(),
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/admin-users'),
                ),
                _StatCard(
                  icon: Icons.restaurant_menu,
                  label: 'Total Posts',
                  value: state.totalPosts.toString(),
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, '/admin-food'),
                ),
                _StatCard(
                  icon: Icons.pending_actions,
                  label: 'Pending Claims',
                  value: state.pendingClaims.toString(),
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(context, '/admin-claims'),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Ratings tab
// ─────────────────────────────────────────────

class _RatingsTab extends StatelessWidget {
  const _RatingsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminRatingsBloc, AdminRatingsState>(
      builder: (context, state) {
        if (state is AdminRatingsLoading || state is AdminRatingsInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AdminRatingsError) {
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
                      .read<AdminRatingsBloc>()
                      .add(FetchRatingsEvent()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is AdminRatingsLoaded) {
          if (state.ratings.isEmpty) {
            return const Center(child: Text('No ratings yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.ratings.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final rating = state.ratings[index];
              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < rating.score ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
                ),
                title: Text(
                  rating.comment.isNotEmpty ? rating.comment : '(no comment)',
                ),
                subtitle: Text(
                  'Donor: ${rating.donorUid} · Receiver: ${rating.receiverUid}',
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}