import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/features/auth/domain/entities/user_entity.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:foodbank/features/claim/presentation/bloc/claim_bloc.dart';
import 'package:foodbank/features/claim/presentation/bloc/claim_event.dart';
import 'package:foodbank/features/claim/presentation/bloc/claim_state.dart';
import 'package:foodbank/features/food_post/domain/entities/food_post_entity.dart';
import 'package:foodbank/injection_container.dart';

class FoodDetailPage extends StatelessWidget {
  final FoodPostEntity post;

  const FoodDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ClaimBloc>(),
      child: _FoodDetailView(post: post),
    );
  }
}

class _FoodDetailView extends StatefulWidget {
  final FoodPostEntity post;

  const _FoodDetailView({required this.post});

  @override
  State<_FoodDetailView> createState() => _FoodDetailViewState();
}

class _FoodDetailViewState extends State<_FoodDetailView> {
  final _pageController = PageController();
  int _currentPage = 0;
  String? _donorPhone;

  @override
  void initState() {
    super.initState();
    _loadDonorPhone();
  }

  Future<void> _loadDonorPhone() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.post.donorId)
          .get();
      if (mounted && doc.exists) {
        final phone = doc.data()?['phoneNumber'] as String?;
        if (phone != null && phone.isNotEmpty) {
          setState(() => _donorPhone = phone);
        }
      }
    } catch (_) {}
  }

  Future<void> _callDonor() async {
    if (_donorPhone == null) return;
    final uri = Uri.parse('tel:$_donorPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<ClaimBloc, ClaimState>(
        listener: (context, state) {
          if (state.status == ClaimStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.successMessage ?? 'Klaim berhasil!',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            Navigator.of(context).pop();
          }
          if (state.status == ClaimStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? 'Gagal mengklaim',
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
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 16),
                    _buildInfoCards(),
                    const SizedBox(height: 20),
                    _buildDescription(),
                    const SizedBox(height: 20),
                    _buildDonorInfo(),
                    const SizedBox(height: 20),
                    _buildMap(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildClaimButton(context, user),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final images = widget.post.imageUrls;
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: images.isEmpty
            ? Container(
                color: AppColors.border,
                child: const Icon(Icons.fastfood_outlined, size: 64, color: AppColors.textSecondary),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, e) => Container(
                        color: AppColors.border,
                        child: const Icon(Icons.fastfood_outlined, size: 64, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                  if (images.length > 1)
                    Positioned(
                      top: 12,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentPage + 1}/${images.length}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.post.title,
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.scale_outlined,
            label: 'Jumlah',
            value: '${widget.post.quantity.toStringAsFixed(0)} g',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.schedule_outlined,
            label: 'Kedaluwarsa',
            value: DateFormat('dd MMM yyyy').format(widget.post.expiredAt),
            valueColor: widget.post.expiredAt.difference(DateTime.now()).inDays < 2
                ? AppColors.error
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.post.description,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildDonorInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 20,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Donor',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  widget.post.donorName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_donorPhone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _donorPhone!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_donorPhone != null)
            IconButton(
              onPressed: _callDonor,
              icon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 22),
              tooltip: 'Hubungi Donor',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final point = LatLng(widget.post.location.latitude, widget.post.location.longitude);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokasi Pickup',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.post.location.address,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.foodbank.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin, color: AppColors.primary, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openMaps(widget.post.location.latitude, widget.post.location.longitude),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: Text(
              'Buka di Maps',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openMaps(double lat, double lng) async {
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  Widget _buildClaimButton(BuildContext context, UserEntity? user) {
    return BlocBuilder<ClaimBloc, ClaimState>(
      builder: (context, state) {
        final isLoading = state.status == ClaimStatus.loading;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        context.read<ClaimBloc>().add(CreateClaim(
                              foodId: widget.post.id,
                              foodTitle: widget.post.title,
                              foodImageUrl: widget.post.imageUrls.isNotEmpty ? widget.post.imageUrls.first : '',
                              donorId: widget.post.donorId,
                              donorName: widget.post.donorName,
                              receiverId: user?.uid ?? '',
                              receiverName: user?.fullName ?? '',
                            ));
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Klaim Makanan',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
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
