import 'package:flutter/material.dart';
import 'package:mydailymeal/dashboard.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        '/login' : (context) => const Login(),
        '/dashboard' : (context) => const Dashboard()
      }
    );
  }
}

