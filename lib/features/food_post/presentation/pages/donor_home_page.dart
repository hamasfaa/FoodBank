import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:foodbank/features/food_post/domain/entities/food_post_entity.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_bloc.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_event.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_state.dart';
import 'package:foodbank/injection_container.dart';
import 'create_food_post_page.dart';

class DonorHomePage extends StatelessWidget {
  const DonorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    return BlocProvider(
      create: (_) => sl<FoodPostBloc>()..add(LoadMyFoodPosts(user?.uid ?? '')),
      child: _DonorHomeView(userName: user?.fullName ?? 'Donor'),
    );
  }
}

class _DonorHomeView extends StatelessWidget {
  final String userName;

  const _DonorHomeView({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFAB(context),
      body: BlocListener<FoodPostBloc, FoodPostState>(
        listener: (context, state) {
          if (state.status == FoodPostStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? 'Terjadi kesalahan',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        child: BlocBuilder<FoodPostBloc, FoodPostState>(
          builder: (context, state) {
            if (state.status == FoodPostStatus.loadingPosts) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state.myPosts.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                final authState = context.read<AuthBloc>().state;
                context.read<FoodPostBloc>().add(
                  LoadMyFoodPosts(authState.user?.uid ?? ''),
                );
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: state.myPosts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _FoodPostCard(post: state.myPosts[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, $userName',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Donasi makananmu hari ini',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: Text(
        'Donasi Makanan',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      onPressed: () async {
        final bloc = context.read<FoodPostBloc>();
        final authState = context.read<AuthBloc>().state;

        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: const CreateFoodPostPage(),
            ),
          ),
        );

        if (result == true) {
          bloc.add(LoadMyFoodPosts(authState.user?.uid ?? ''));
        }
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Postingan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai donasikan makananmu agar bisa dinikmati orang lain.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(
                'Buat Postingan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                final bloc = context.read<FoodPostBloc>();
                final authState = context.read<AuthBloc>().state;
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: bloc,
                          child: const CreateFoodPostPage(),
                        ),
                      ),
                    )
                    .then((result) {
                      if (result == true) {
                        bloc.add(LoadMyFoodPosts(authState.user?.uid ?? ''));
                      }
                    });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodPostCard extends StatelessWidget {
  final FoodPostEntity post;

  const _FoodPostCard({required this.post});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Image.network(
              post.imageUrls.isNotEmpty ? post.imageUrls.first : '',
              width: 110,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 110,
                height: 120,
                color: AppColors.border,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusBadge(status: post.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.scale_outlined,
                    text: '${post.quantity.toStringAsFixed(0)} g',
                  ),
                  const SizedBox(height: 3),
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    text:
                        'Exp: ${DateFormat('dd MMM yyyy').format(post.expiredAt)}',
                  ),
                  const SizedBox(height: 3),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: post.location.address,
                    maxLines: 1,
                  ),
                ],
              ),
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
      'available' => (AppColors.success, 'Tersedia'),
      'reserved' => (const Color(0xFFF59E0B), 'Dipesan'),
      'taken' => (AppColors.textSecondary, 'Diambil'),
      'expired' => (AppColors.error, 'Kadaluarsa'),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _InfoRow({required this.icon, required this.text, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
