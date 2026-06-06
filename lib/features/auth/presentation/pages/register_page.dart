import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foodbank/core/constants/app_colors.dart';
import 'package:foodbank/core/constants/app_strings.dart';
import 'package:foodbank/core/utils/validators.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_event.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_state.dart';
import 'package:foodbank/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:foodbank/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:foodbank/features/auth/presentation/widgets/role_selector_widget.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _autoValidate = false;
  String? _roleError;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onSubmit(AuthState state) {
    final isFormValid = _formKey.currentState!.validate();
    final hasRole = state.selectedRole != null;

    setState(() {
      _autoValidate = true;
      _roleError = hasRole ? null : AppStrings.validRole;
    });

    if (!isFormValid || !hasRole) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
      return;
    }

    context.read<AuthBloc>().add(
      RegisterSubmitted(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        role: state.selectedRole!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? AppStrings.errorGeneral,
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else if (state.status == AuthStatus.needsProfile) {
          Navigator.pushNamed(context, '/complete-profile');
        } else if (state.status == AuthStatus.success && state.user != null) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return Form(
                    key: _formKey,
                    autovalidateMode: _autoValidate
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildFormFields(state),
                        const SizedBox(height: 24),
                        _buildRoleSelector(state),
                        const SizedBox(height: 28),
                        _buildSubmitButton(state),
                        const SizedBox(height: 16),
                        _buildDivider(),
                        const SizedBox(height: 16),
                        _buildGoogleButton(state),
                        const SizedBox(height: 24),
                        _buildLoginLink(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.createAccount,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.createAccountSubtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(AuthState state) {
    return Column(
      children: [
        CustomTextField(
          controller: _fullNameController,
          label: AppStrings.fullName,
          prefixIcon: Icons.person_outline,
          focusNode: _fullNameFocus,
          nextFocusNode: _emailFocus,
          textInputAction: TextInputAction.next,
          validator: Validators.fullName,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          label: AppStrings.email,
          prefixIcon: Icons.email_outlined,
          focusNode: _emailFocus,
          nextFocusNode: _phoneFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.email,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _phoneController,
          label: AppStrings.phoneNumber,
          prefixIcon: Icons.phone_outlined,
          focusNode: _phoneFocus,
          nextFocusNode: _passwordFocus,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: Validators.phoneNumber,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          label: AppStrings.password,
          prefixIcon: Icons.lock_outline,
          focusNode: _passwordFocus,
          nextFocusNode: _confirmPasswordFocus,
          obscureText: !state.isPasswordVisible,
          textInputAction: TextInputAction.next,
          validator: Validators.password,
          onChanged: (_) {
            if (_autoValidate) _formKey.currentState?.validate();
          },
          suffixIcon: IconButton(
            icon: Icon(
              state.isPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () =>
                context.read<AuthBloc>().add(const PasswordVisibilityToggled()),
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmPasswordController,
          label: AppStrings.confirmPassword,
          prefixIcon: Icons.lock_outline,
          focusNode: _confirmPasswordFocus,
          obscureText: !state.isConfirmPasswordVisible,
          textInputAction: TextInputAction.done,
          validator: (value) =>
              Validators.confirmPassword(_passwordController.text)(value),
          suffixIcon: IconButton(
            icon: Icon(
              state.isConfirmPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () => context.read<AuthBloc>().add(
              const ConfirmPasswordVisibilityToggled(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.roleTitle,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        RoleSelectorWidget(
          selectedRole: state.selectedRole,
          onRoleSelected: (role) {
            context.read<AuthBloc>().add(RoleSelected(role));
            if (_roleError != null) {
              setState(() => _roleError = null);
            }
          },
        ),
        if (_roleError != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _roleError!,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(AuthState state) {
    final isLoading = state.status == AuthStatus.loading;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _onSubmit(state),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                AppStrings.registerNow,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppStrings.orDivider,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildGoogleButton(AuthState state) {
    return GoogleSignInButton(
      isLoading: state.status == AuthStatus.loading,
      onPressed: () =>
          context.read<AuthBloc>().add(const GoogleSignInRequested()),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.alreadyHaveAccount,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text(
              AppStrings.login,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
