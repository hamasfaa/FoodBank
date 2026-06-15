import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbank/core/services/notification_service.dart';
import 'package:foodbank/core/theme/app_theme.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:foodbank/features/auth/presentation/bloc/auth_state.dart';
import 'package:foodbank/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:foodbank/features/auth/presentation/pages/login_page.dart';
import 'package:foodbank/features/auth/presentation/pages/register_page.dart';
import 'package:foodbank/firebase_options.dart';
import 'package:foodbank/injection_container.dart';
import 'package:foodbank/admin_users_page.dart';
import 'package:foodbank/features/food_post/presentation/pages/donor_home_page.dart';
import 'package:foodbank/features/food_post/presentation/pages/receiver_home_page.dart';
import 'package:foodbank/features/claim/presentation/pages/donor_claims_page.dart';
import 'package:foodbank/features/claim/presentation/pages/my_claims_page.dart';
import 'package:foodbank/features/profile/presentation/pages/donor_profile_page.dart';
import 'package:foodbank/features/profile/presentation/pages/receiver_profile_page.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FlutterError.onError = (errorDetails) {
    FlutterError.presentError(errorDetails);
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    return true;
  };

  await configureDependencies();
  try {
    await sl<NotificationService>().initialize();
  } catch (error, stackTrace) {
    await FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
  _listenForFcmForegroundNotifications();
  await initializeDateFormatting('id_ID', null);
  runApp(const FoodBankApp());
}

void _listenForFcmForegroundNotifications() {
  FirebaseMessaging.onMessage.listen((message) {
    if (message.data['notificationId'] != null) return;

    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    if (title == null && body == null) return;

    _showNotificationSnack(title, body);
  });
}

void _showNotificationSnack(String? title, String? body) {
  final message = [
    title,
    body,
  ].whereType<String>().where((text) => text.trim().isNotEmpty).join('\n');
  if (message.isEmpty) return;

  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class FoodBankApp extends StatelessWidget {
  const FoodBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          return current.status == AuthStatus.success &&
              current.user != null &&
              previous.user?.uid != current.user?.uid;
        },
        listener: (context, state) {
          final service = sl<NotificationService>();
          unawaited(service.syncTokenForUser(state.user!.uid));
          unawaited(
            service.listenForUserNotifications(
              uid: state.user!.uid,
              onNotification: _showNotificationSnack,
            ),
          );
        },
        child: MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
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
            '/donor-claims': (context) => const DonorClaimsPage(),
            '/my-claims': (context) => const MyClaimsPage(),
            '/donor-profile': (context) => const DonorProfilePage(),
            '/receiver-profile': (context) => const ReceiverProfilePage(),
          },
        ),
      ),
    );
  }
}
