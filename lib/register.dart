import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameCTRL = TextEditingController();
  final TextEditingController _emailCTRL = TextEditingController();
  final TextEditingController _passCTRL = TextEditingController();
  final TextEditingController _confirmpassCTRL = TextEditingController();
  final TextEditingController _ageCTRL = TextEditingController();

  DateTime? _birthDate;
  String _gender = 'Male';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(50),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick a username',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextFormField(
                        controller: _usernameCTRL,
                        keyboardType: TextInputType.text,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Enter your username' : null,
                        decoration: InputDecoration(
                          hintText: 'Emelia Tan',
                          filled: true,
                          fillColor: Colors.black12,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 20.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextFormField(
                        controller: _emailCTRL,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          filled: true,
                          fillColor: Colors.black12,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 20.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Enter email'
                                    : (!value.contains('@')
                                        ? 'Invalid email follow the format: abc@gmail.com'
                                        : null),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextFormField(
                        controller: _passCTRL,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          filled: true,
                          fillColor: Colors.black12,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 20.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator:
                            (value) =>
                                value!.length < 6
                                    ? 'Password must be at least 6 characters'
                                    : null,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Confirm Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextFormField(
                        controller: _confirmpassCTRL,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Confirm your password',
                          filled: true,
                          fillColor: Colors.black12,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 20.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Confirm your password';
                          }
                          if (value != _passCTRL.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Pick your date of birth',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextFormField(
                        controller: _ageCTRL,
                        readOnly: true,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Select your birthday' : null,
                        decoration: InputDecoration(
                          labelText: 'Date of birth',
                          filled: true,
                          fillColor: Colors.black12,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null) {
                            setState(() {
                              _birthDate = pickedDate;
                              _ageCTRL.text =
                                  '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                            });
                          }
                        },
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        items:
                            ['Male', 'Female'].map((gender) {
                              return DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.black12,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 43,
                        child: ElevatedButton(
                          onPressed: () {
                            _register();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick your date of birth')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Step 1: Create User in FirebaseAuth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCTRL.text.trim(),
            password: _passCTRL.text.trim(),
          );

      // Step 2: Calculate Age
      int age = _calculateAge(_birthDate!);

      // Step 3: Save User Info to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': _emailCTRL.text.trim(),
            'username': _usernameCTRL.text.trim(),
            'age': age,
            'birthDate': _birthDate,
            'gender': _gender,
            'image': '', // Empty for now
            'isAdmin': false,
          });

      // Step 4: Navigate or Show Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Successful'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamed(context, '/login');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Error: ${e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
