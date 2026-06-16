import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/core/widgets/receiver_navigation_bar.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:foodbank/features/food_post/domain/entities/food_post_entity.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_bloc.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_event.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_state.dart';
import 'package:foodbank/injection_container.dart';
import 'food_detail_page.dart';

enum _FoodFilter { all, expiringSoon, newest }

class ReceiverHomePage extends StatelessWidget {
  const ReceiverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FoodPostBloc>()..add(const LoadAvailableFoodPosts()),
      child: const _ReceiverHomeView(),
    );
  }
}

class _ReceiverHomeView extends StatefulWidget {
  const _ReceiverHomeView();

  @override
  State<_ReceiverHomeView> createState() => _ReceiverHomeViewState();
}

class _ReceiverHomeViewState extends State<_ReceiverHomeView> {
  final _searchController = TextEditingController();
  String _query = '';
  _FoodFilter _filter = _FoodFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodPostEntity> _filteredPosts(List<FoodPostEntity> posts) {
    final q = _query.trim().toLowerCase();
    final now = DateTime.now();

    return posts.where((p) {
      final matchesQuery = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.donorName.toLowerCase().contains(q) ||
          p.location.address.toLowerCase().contains(q);

      final matchesFilter = switch (_filter) {
        _FoodFilter.all => true,
        _FoodFilter.expiringSoon =>
          p.expiredAt.difference(now).inDays <= 3,
        _FoodFilter.newest =>
          now.difference(p.createdAt).inDays <= 1,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  bool get _hasActiveFilter =>
      _query.trim().isNotEmpty || _filter != _FoodFilter.all;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, user?.fullName ?? 'Penerima'),
      bottomNavigationBar: const ReceiverNavigationBar(
        currentItem: ReceiverNavItem.home,
      ),
      body: BlocListener<FoodPostBloc, FoodPostState>(
        listener: (context, state) {
          if (ModalRoute.of(context)?.isCurrent != true) return;

          if (state.status == FoodPostStatus.failure) {
            _showSnack(
              context,
              state.errorMessage ?? 'Terjadi kesalahan',
              isError: true,
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

            final posts = _filteredPosts(state.availablePosts);

            if (state.availablePosts.isEmpty) {
              return Column(
                children: [
                  _buildSearchAndFilters(),
                  Expanded(child: _buildEmptyState()),
                ],
              );
            }

            return Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: posts.isEmpty
                      ? _buildNoResultsState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            context
                                .read<FoodPostBloc>()
                                .add(const LoadAvailableFoodPosts());
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            itemCount: posts.length,
                            separatorBuilder: (_, i) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) => _FoodCard(
                              post: posts[i],
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FoodDetailPage(post: posts[i]),
                                ),
                              ),
                            ),
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

  AppBar _buildAppBar(BuildContext context, String userName) {
    final currentName =
        context.watch<AuthBloc>().state.user?.fullName ?? userName;

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, $currentName',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Temukan makanan tersedia hari ini',
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

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _query = val),
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Cari makanan, donor, lokasi...',
              hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _FoodFilter.values.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (_, index) =>
                  _buildFilterChip(_FoodFilter.values[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(_FoodFilter filter) {
    final selected = filter == _filter;
    final foreground = selected ? Colors.white : AppColors.textPrimary;
    final iconColor = selected ? Colors.white : _filterColor(filter);

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
              Icon(_filterIcon(filter), size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                _filterLabel(filter),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                Icons.no_food_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Makanan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada donasi makanan tersedia saat ini.',
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

  Widget _buildNoResultsState() {
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
              child: const Icon(
                Icons.search_off_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tidak Ada Hasil',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci atau filter lain.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilter) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                    _filter = _FoodFilter.all;
                  });
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  'Reset Filter',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _filterLabel(_FoodFilter filter) {
    return switch (filter) {
      _FoodFilter.all => 'Semua',
      _FoodFilter.expiringSoon => 'Segera Exp',
      _FoodFilter.newest => 'Terbaru',
    };
  }

  IconData _filterIcon(_FoodFilter filter) {
    return switch (filter) {
      _FoodFilter.all => Icons.tune_outlined,
      _FoodFilter.expiringSoon => Icons.event_busy_outlined,
      _FoodFilter.newest => Icons.new_releases_outlined,
    };
  }

  Color _filterColor(_FoodFilter filter) {
    return switch (filter) {
      _FoodFilter.all => AppColors.textSecondary,
      _FoodFilter.expiringSoon => AppColors.error,
      _FoodFilter.newest => AppColors.success,
    };
  }

  void _showSnack(BuildContext context, String message,
      {bool isError = false}) {
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
}

class _FoodCard extends StatelessWidget {
  final FoodPostEntity post;
  final VoidCallback onTap;

  const _FoodCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                errorBuilder: (ctx, err, st) => Container(
                  width: 110,
                  height: 120,
                  color: AppColors.border,
                  child: const Icon(
                    Icons.fastfood_outlined,
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
                    Text(
                      post.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    _InfoRow(icon: Icons.person_outline, text: post.donorName),
                    const SizedBox(height: 3),
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

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
            style:
                GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
