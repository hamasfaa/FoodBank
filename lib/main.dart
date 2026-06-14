import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/core/theme/app_theme.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:foodbank/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:foodbank/features/auth/presentation/pages/login_page.dart';
import 'package:foodbank/features/auth/presentation/pages/register_page.dart';
import 'package:foodbank/firebase_options.dart';
import 'package:foodbank/injection_container.dart';
import 'package:foodbank/admin_users_page.dart';
import 'package:foodbank/features/food_post/presentation/pages/donor_home_page.dart';
import 'package:foodbank/features/food_post/presentation/pages/receiver_home_page.dart';
import 'package:foodbank/features/claim/presentation/pages/my_claims_page.dart';
import 'package:foodbank/features/profile/presentation/pages/donor_profile_page.dart';
import 'package:foodbank/features/profile/presentation/pages/receiver_profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();
  await initializeDateFormatting('id_ID', null);
  runApp(const FoodBankApp());
}

class FoodBankApp extends StatelessWidget {
  const FoodBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: MaterialApp(
        title: 'FoodBridge',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/login',
        routes: {
          '/register': (context) => const RegisterPage(),
          '/complete-profile': (context) => const CompleteProfilePage(),
          '/login': (context) => const LoginPage(),
          '/admin-users': (context) => const AdminUsersPage(),
          '/donor-home': (context) => const DonorHomePage(),
          '/receiver-home': (context) => const ReceiverHomePage(),
          '/my-claims': (context) => const MyClaimsPage(),
          '/donor-profile': (context) => const DonorProfilePage(),
          '/receiver-profile': (context) => const ReceiverProfilePage(),
        },
      ),
    );
  }
}
