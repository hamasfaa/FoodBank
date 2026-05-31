import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/core/constants/app_strings.dart';

class RoleSelectorWidget extends StatelessWidget {
  final String? selectedRole;
  final void Function(String) onRoleSelected;

  const RoleSelectorWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _RoleCard(
              role: 'donor',
              label: AppStrings.rolePemberi,
              sublabel: AppStrings.rolePemberiSub,
              activeIcon: Icons.volunteer_activism_rounded,
              inactiveIcon: Icons.volunteer_activism_outlined,
              isSelected: selectedRole == 'donor',
              onTap: () => onRoleSelected('donor'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _RoleCard(
              role: 'receiver',
              label: AppStrings.rolePenerima,
              sublabel: AppStrings.rolePenerimaSub,
              activeIcon: Icons.handshake_rounded,
              inactiveIcon: Icons.handshake_outlined,
              isSelected: selectedRole == 'receiver',
              onTap: () => onRoleSelected('receiver'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final String label;
  final String sublabel;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.label,
    required this.sublabel,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.4,
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.75)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
