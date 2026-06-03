import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/injection_container.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'unknown',
    );
  }
}

abstract class AdminUsersEvent {}

class FetchUsersEvent extends AdminUsersEvent {}

abstract class AdminUsersState {}

class AdminUsersInitial extends AdminUsersState {}

class AdminUsersLoading extends AdminUsersState {}

class AdminUsersLoaded extends AdminUsersState {
  final List<UserModel> users;
  AdminUsersLoaded(this.users);
}

class AdminUsersError extends AdminUsersState {
  final String message;
  AdminUsersError(this.message);
}

class AdminUsersBloc extends Bloc<AdminUsersEvent, AdminUsersState> {
  final FirebaseFirestore _firestore;

  AdminUsersBloc(this._firestore) : super(AdminUsersInitial()) {
    on<FetchUsersEvent>(_onFetchUsers);
  }

  Future<void> _onFetchUsers(
    FetchUsersEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    emit(AdminUsersLoading());
    try {
      final snapshot = await _firestore.collection('users').get();
      print('Docs found: ${snapshot.docs.length}');
      final users = snapshot.docs.map(UserModel.fromFirestore).toList();
      emit(AdminUsersLoaded(users));
    } catch (e) {
      emit(AdminUsersError(e.toString()));
    }
  }
}

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AdminUsersBloc(sl<FirebaseFirestore>())..add(FetchUsersEvent()),
      child: const _AdminUsersView(),
    );
  }
}

class _AdminUsersView extends StatelessWidget {
  const _AdminUsersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<AdminUsersBloc>().add(FetchUsersEvent()),
          ),
        ],
      ),
      body: BlocBuilder<AdminUsersBloc, AdminUsersState>(
        builder: (context, state) {
          if (state is AdminUsersLoading || state is AdminUsersInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminUsersError) {
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
                        .read<AdminUsersBloc>()
                        .add(FetchUsersEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is AdminUsersLoaded) {
            if (state.users.isEmpty) {
              return const Center(child: Text('No users found.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = state.users[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(user.name.isNotEmpty ? user.name : '(no name)'),
                  subtitle: Text(user.email),
                  trailing: Chip(
                    label: Text(
                      user.role,
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
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