import 'package:e_commerce_app/routes.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/user_provider.dart';
import 'firebase_options.dart';
import 'features/authentication/screens/login_screen.dart';
import 'core/constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await FirebaseAppCheck.instance.activate(
  //   // webRecaptchaSiteKey: 'recaptcha-v3-site-key',  // Only needed for web
  //   androidProvider: AndroidProvider.debug,  // Use .playIntegrity for production
  //   appleProvider: AppleProvider.appAttest,  // For iOS/macOS
  // );
  // String? token = await FirebaseAppCheck.instance.getToken(true);
  // print('Debug App Check token: $token');

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
        child:MaterialApp(
          initialRoute: AppRoutes.login,
          onGenerateRoute: AppRouter.generateRoute,
          title: 'Auth App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            scaffoldBackgroundColor: AppColors.background,
            fontFamily: 'Roboto',
          ),
        )
    );
  }
}