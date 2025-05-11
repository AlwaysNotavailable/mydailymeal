import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Resetpassword extends StatefulWidget {
  const Resetpassword({super.key});

  @override
  State<Resetpassword> createState() => _ResetpasswordState();
}

class _ResetpasswordState extends State<Resetpassword> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailCTRL = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Reset Password'),
        backgroundColor: Colors.white,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                padding: const EdgeInsets.all(50),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        'Enter the email that you used to create your account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextFormField(
                        controller: _emailCTRL,
                        keyboardType: TextInputType.text,
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Enter email'
                                    : (!value.contains('@')
                                        ? 'Invalid email follow the format: abc@gmail.com'
                                        : null),
                        decoration: InputDecoration(
                          hintText: 'Your Email Address',
                          filled: true,
                          fillColor: Colors.black12,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 20.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 43,
                        child: ElevatedButton(
                          onPressed: () {
                            _resetpassword(_emailCTRL.text);
                          },
                          child: Text('Send Reset Link'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _resetpassword(String email) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      // Check if email exists in your Firestore users collection
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (userQuery.docs.isNotEmpty) {
        // Email found in Firestore → send reset email
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent!'),
          backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamed(context, '/login');
      } else {
        // Email not found in Firestore
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found with this email'),
          backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Login failed'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _loading = false);
    }
  }
}


