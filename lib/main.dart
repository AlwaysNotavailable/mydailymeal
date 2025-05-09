import 'package:flutter/material.dart';
import 'package:mydailymeal/dashboard.dart';
import 'package:mydailymeal/register.dart';
import 'IdealWeight.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'meal/meal.dart';
import 'resetpassword.dart';
import 'profile.dart';
import 'edit_profile.dart';
import 'Home.dart';
import 'adminPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDailyMeal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const Login(),
        '/dashboard': (context) => const Dashboard(),
        '/register': (context) => const Register(),
        '/resetpassword': (context) => const Resetpassword(),
        '/profile': (context) => Profile(),
        '/edit_profile': (context) => EditProfilePage(),
        '/home': (context) => Home(),
        '/IdealWeight': (context) => IdealWeight(),
        '/MealPage': (context) => MealPage(),
        '/adminPage': (context) => adminPage(),
      },
    );
  }
}
