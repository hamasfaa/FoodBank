import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/injection_container.dart';

// ─────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────

class FoodModel {
  final String id;
  final String title;
  final String description;
  final int quantity;
  final String status; // AVAILABLE | CLAIMED | CLOSED | EXPIRED
  final String donorUid;
  final String imageUrl;
  final DateTime? expiredAt;

  const FoodModel({
    required this.id,
    required this.title,
    required this.description,
    required this.quantity,
    required this.status,
    required this.donorUid,
    required this.imageUrl,
    required this.expiredAt,
  });

  factory FoodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      quantity: data['quantity'] ?? 0,
      status: data['status'] ?? 'UNKNOWN',
      donorUid: data['donorUid'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      expiredAt: (data['expiredAt'] as Timestamp?)?.toDate(),
    );
  }

  FoodModel copyWith({String? status}) {
    return FoodModel(
      id: id,
      title: title,
      description: description,
      quantity: quantity,
      status: status ?? this.status,
      donorUid: donorUid,
      imageUrl: imageUrl,
      expiredAt: expiredAt,
    );
  }
}

// ─────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────

abstract class AdminFoodEvent {}

class FetchFoodsEvent extends AdminFoodEvent {}

class CloseFoodEvent extends AdminFoodEvent {
  final String foodId;
  CloseFoodEvent(this.foodId);
}

// ─────────────────────────────────────────────
// States
// ─────────────────────────────────────────────

abstract class AdminFoodState {}

class AdminFoodInitial extends AdminFoodState {}

class AdminFoodLoading extends AdminFoodState {}

class AdminFoodLoaded extends AdminFoodState {
  final List<FoodModel> foods;
  final String? actionError;
  AdminFoodLoaded(this.foods, {this.actionError});
}

class AdminFoodError extends AdminFoodState {
  final String message;
  AdminFoodError(this.message);
}

// ─────────────────────────────────────────────
// Bloc
// ─────────────────────────────────────────────

class AdminFoodBloc extends Bloc<AdminFoodEvent, AdminFoodState> {
  final FirebaseFirestore _firestore;

  AdminFoodBloc(this._firestore) : super(AdminFoodInitial()) {
    on<FetchFoodsEvent>(_onFetchFoods);
    on<CloseFoodEvent>(_onCloseFood);
  }

  Future<void> _onFetchFoods(
    FetchFoodsEvent event,
    Emitter<AdminFoodState> emit,
  ) async {
    emit(AdminFoodLoading());
    try {
      final snapshot = await _firestore
          .collection('foods')
          .orderBy('createdAt', descending: true)
          .get();
      final foods = snapshot.docs.map(FoodModel.fromFirestore).toList();
      emit(AdminFoodLoaded(foods));
    } catch (e) {
      emit(AdminFoodError(e.toString()));
    }
  }

  Future<void> _onCloseFood(
    CloseFoodEvent event,
    Emitter<AdminFoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AdminFoodLoaded) return;

    final updated = currentState.foods.map((f) {
      return f.id == event.foodId ? f.copyWith(status: 'CLOSED') : f;
    }).toList();
    emit(AdminFoodLoaded(updated));

    try {
      await _firestore
          .collection('foods')
          .doc(event.foodId)
          .update({'status': 'CLOSED'});
    } catch (e) {
      emit(AdminFoodLoaded(currentState.foods, actionError: e.toString()));
    }
  }
}

// ─────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────

class AdminFoodPage extends StatelessWidget {
  const AdminFoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AdminFoodBloc(sl<FirebaseFirestore>())..add(FetchFoodsEvent()),
      child: const _AdminFoodView(),
    );
  }
}

class _AdminFoodView extends StatelessWidget {
  const _AdminFoodView();

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'CLAIMED':
        return Colors.orange;
      case 'CLOSED':
        return Colors.grey;
      case 'EXPIRED':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Food Posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<AdminFoodBloc>().add(FetchFoodsEvent()),
          ),
        ],
      ),
      body: BlocConsumer<AdminFoodBloc, AdminFoodState>(
        listener: (context, state) {
          if (state is AdminFoodLoaded && state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Action failed: ${state.actionError}')),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminFoodLoading || state is AdminFoodInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminFoodError) {
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
                        context.read<AdminFoodBloc>().add(FetchFoodsEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is AdminFoodLoaded) {
            if (state.foods.isEmpty) {
              return const Center(child: Text('No food posts found.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.foods.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final food = state.foods[index];
                final canClose =
                    food.status == 'AVAILABLE' || food.status == 'CLAIMED';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: food.imageUrl.isNotEmpty
                        ? NetworkImage(food.imageUrl)
                        : null,
                    child: food.imageUrl.isEmpty
                        ? const Icon(Icons.restaurant)
                        : null,
                  ),
                  title: Text(food.title.isNotEmpty ? food.title : '(no title)'),
                  subtitle: Text('Qty: ${food.quantity} · Donor: ${food.donorUid}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          food.status,
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                        backgroundColor: _statusColor(food.status),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      if (canClose)
                        TextButton(
                          onPressed: () => context
                              .read<AdminFoodBloc>()
                              .add(CloseFoodEvent(food.id)),
                          child: const Text('Close'),
                        ),
                    ],
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