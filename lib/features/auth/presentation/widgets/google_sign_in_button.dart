import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/core/constants/app_strings.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 10),
                  Text(
                    AppStrings.continueWithGoogle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        children: [
          Center(
            child: Text(
              'G',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4285F4),
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
