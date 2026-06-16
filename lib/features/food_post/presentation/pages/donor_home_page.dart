import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/core/widgets/donor_navigation_bar.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:foodbank/features/food_post/domain/entities/food_post_entity.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_bloc.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_event.dart';
import 'package:foodbank/features/food_post/presentation/bloc/food_post_state.dart';
import 'package:foodbank/injection_container.dart';
import 'create_food_post_page.dart';
import 'edit_food_post_page.dart';

enum _DonorPostFilter { all, available, claimed, closed, expired }

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

class _DonorHomeView extends StatefulWidget {
  final String userName;

  const _DonorHomeView({required this.userName});

  @override
  State<_DonorHomeView> createState() => _DonorHomeViewState();
}

class _DonorHomeViewState extends State<_DonorHomeView> {
  final _searchController = TextEditingController();
  String _query = '';
  _DonorPostFilter _filter = _DonorPostFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodPostEntity> _filteredPosts(List<FoodPostEntity> posts) {
    final q = _query.trim().toLowerCase();
    return posts.where((post) {
      final matchesQuery =
          q.isEmpty ||
          post.title.toLowerCase().contains(q) ||
          post.description.toLowerCase().contains(q) ||
          post.location.address.toLowerCase().contains(q) ||
          _statusLabel(post.status).toLowerCase().contains(q);

      final matchesFilter = switch (_filter) {
        _DonorPostFilter.all => true,
        _DonorPostFilter.available => post.status == 'available',
        _DonorPostFilter.closed => post.status == 'closed',
        _DonorPostFilter.expired => post.status == 'expired',
        _DonorPostFilter.claimed =>
          post.status == 'claimed' || post.status == 'reserved',
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  bool get _hasActiveSearchOrFilter =>
      _query.trim().isNotEmpty || _filter != _DonorPostFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFAB(context),
      bottomNavigationBar: const DonorNavigationBar(
        currentItem: DonorNavItem.donations,
      ),
      body: BlocListener<FoodPostBloc, FoodPostState>(
        listener: (context, state) {
          if (ModalRoute.of(context)?.isCurrent != true) return;

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
          } else if (state.status == FoodPostStatus.success &&
              state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.successMessage!,
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppColors.success,
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

            final posts = _filteredPosts(state.myPosts);

            if (state.myPosts.isEmpty) {
              return _buildEmptyState(context);
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
                            final authState = context.read<AuthBloc>().state;
                            context.read<FoodPostBloc>().add(
                              LoadMyFoodPosts(authState.user?.uid ?? ''),
                            );
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            itemCount: posts.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final post = posts[i];
                              return _FoodPostCard(
                                post: post,
                                onEdit: () => _openEditPost(context, post),
                                onClose: () => _confirmClosePost(context, post),
                                onDelete: () =>
                                    _confirmDeletePost(context, post),
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

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Cari postingan, lokasi, status...',
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
              itemCount: _DonorPostFilter.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _DonorPostFilter.values[index];
                return _buildFilterChip(filter);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(_DonorPostFilter filter) {
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
              SizedBox(
                width: 18,
                height: 18,
                child: Icon(_filterIcon(filter), size: 18, color: iconColor),
              ),
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
              'Coba kata kunci atau filter status lain.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveSearchOrFilter) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                    _filter = _DonorPostFilter.all;
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

  String _filterLabel(_DonorPostFilter filter) {
    return switch (filter) {
      _DonorPostFilter.all => 'Semua',
      _DonorPostFilter.available => 'Tersedia',
      _DonorPostFilter.claimed => 'Diklaim',
      _DonorPostFilter.closed => 'Ditutup',
      _DonorPostFilter.expired => 'Kadaluarsa',
    };
  }

  IconData _filterIcon(_DonorPostFilter filter) {
    return switch (filter) {
      _DonorPostFilter.all => Icons.tune_outlined,
      _DonorPostFilter.available => Icons.check_circle_outline,
      _DonorPostFilter.claimed => Icons.receipt_long_outlined,
      _DonorPostFilter.closed => Icons.visibility_off_outlined,
      _DonorPostFilter.expired => Icons.event_busy_outlined,
    };
  }

  Color _filterColor(_DonorPostFilter filter) {
    return switch (filter) {
      _DonorPostFilter.all => AppColors.textSecondary,
      _DonorPostFilter.available => AppColors.success,
      _DonorPostFilter.claimed => const Color(0xFFF59E0B),
      _DonorPostFilter.closed => AppColors.textSecondary,
      _DonorPostFilter.expired => AppColors.error,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'available' => 'Tersedia',
      'claimed' => 'Diklaim',
      'reserved' => 'Dipesan',
      'closed' => 'Ditutup',
      'taken' => 'Diambil',
      'expired' => 'Kadaluarsa',
      _ => status,
    };
  }

  Future<void> _openEditPost(BuildContext context, FoodPostEntity post) async {
    if (post.status != 'available') {
      _showActionError(context, 'Hanya postingan tersedia yang bisa diedit');
      return;
    }

    final bloc = context.read<FoodPostBloc>();
    final authState = context.read<AuthBloc>().state;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: EditFoodPostPage(post: post),
        ),
      ),
    );

    if (result == true && context.mounted) {
      bloc.add(LoadMyFoodPosts(authState.user?.uid ?? ''));
    }
  }

  Future<void> _confirmClosePost(
    BuildContext context,
    FoodPostEntity post,
  ) async {
    if (post.status != 'available') {
      _showActionError(context, 'Hanya postingan tersedia yang bisa ditutup');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Tutup Postingan?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Postingan tidak akan muncul lagi untuk penerima. Klaim yang masih pending akan dibatalkan.',
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
              'Tutup',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final authState = context.read<AuthBloc>().state;
    context.read<FoodPostBloc>().add(
      CloseFoodPostRequested(
        postId: post.id,
        donorId: authState.user?.uid ?? '',
      ),
    );
  }

  Future<void> _confirmDeletePost(
    BuildContext context,
    FoodPostEntity post,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Hapus Postingan?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Postingan dan fotonya akan dihapus permanen. Aksi ini hanya berhasil kalau postingan belum memiliki klaim.',
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
              'Hapus',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final authState = context.read<AuthBloc>().state;
    context.read<FoodPostBloc>().add(
      DeleteFoodPostRequested(
        postId: post.id,
        donorId: authState.user?.uid ?? '',
      ),
    );
  }

  void _showActionError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final currentName =
        context.watch<AuthBloc>().state.user?.fullName ?? widget.userName;

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
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const _FoodPostCard({
    required this.post,
    required this.onEdit,
    required this.onClose,
    required this.onDelete,
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
                      const SizedBox(width: 6),
                      _StatusBadge(status: post.status),
                      _PostActionMenu(
                        post: post,
                        onEdit: onEdit,
                        onClose: onClose,
                        onDelete: onDelete,
                      ),
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

enum _FoodPostAction { edit, close, delete }

class _PostActionMenu extends StatelessWidget {
  final FoodPostEntity post;
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const _PostActionMenu({
    required this.post,
    required this.onEdit,
    required this.onClose,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final canChange = post.status == 'available';

    return PopupMenuButton<_FoodPostAction>(
      tooltip: 'Aksi postingan',
      icon: const Icon(
        Icons.more_vert,
        size: 20,
        color: AppColors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case _FoodPostAction.edit:
            onEdit();
            break;
          case _FoodPostAction.close:
            onClose();
            break;
          case _FoodPostAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        if (canChange)
          PopupMenuItem(
            value: _FoodPostAction.edit,
            child: _ActionMenuItem(icon: Icons.edit_outlined, label: 'Edit'),
          ),
        if (canChange)
          PopupMenuItem(
            value: _FoodPostAction.close,
            child: _ActionMenuItem(
              icon: Icons.visibility_off_outlined,
              label: 'Tutup',
            ),
          ),
        PopupMenuItem(
          value: _FoodPostAction.delete,
          child: _ActionMenuItem(
            icon: Icons.delete_outline,
            label: 'Hapus',
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _ActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _ActionMenuItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.textPrimary;

    return Row(
      children: [
        Icon(icon, size: 18, color: itemColor),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: itemColor)),
      ],
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
      'claimed' => (const Color(0xFFF59E0B), 'Diklaim'),
      'reserved' => (const Color(0xFFF59E0B), 'Dipesan'),
      'closed' => (AppColors.textSecondary, 'Ditutup'),
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
