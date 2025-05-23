import 'package:e_commerce_app/api/firebase_api.dart';
import 'package:e_commerce_app/core/widgets/background_decorations.dart';
import 'package:e_commerce_app/routes.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/user_provider.dart';
import 'features/buyer/services/billing_service.dart';
import 'features/buyer/services/notification_service.dart';
import 'firebase_options.dart';
import 'features/authentication/screens/login_screen.dart';
import 'core/constants/colors.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No need to call Firebase.initializeApp() here if it's already initialized in main()
  debugPrint('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notifications
  // await NotificationService.initialize();
  //
  // // Set up token refresh listener
  // NotificationService.setupTokenRefresh();

  try {
    await BillingService().initialize();
  } catch (e) {
    print('Billing initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => UserProvider()),
        ],
        child:AppLifecycleManager(
          child: MaterialApp(
            initialRoute: AppRoutes.initial,
            onGenerateRoute: AppRouter.generateRoute,
            title: 'Auth App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: AppColors.primary,
              colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
              scaffoldBackgroundColor: AppColors.background,
              fontFamily: 'Roboto',
            ),
          ),
        )
    );
  }
}

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BackgroundDecorations().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      BackgroundDecorations().dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}