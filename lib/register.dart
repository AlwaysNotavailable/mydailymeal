import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';


class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}


Future<void> registerUser (String email, String password) async {
  try {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password
    );
    Text('Registration successful');
  } on FirebaseException catch (e) {
    Text('Registration failed: ${e.message}');
  }
}