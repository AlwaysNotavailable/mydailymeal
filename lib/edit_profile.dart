import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _usernameCTRL = TextEditingController();
  final TextEditingController _ageCTRL = TextEditingController();
  final TextEditingController _heightCTRL = TextEditingController();
  final TextEditingController _weightCTRL = TextEditingController();
  String? _imageUrl;
  XFile? _pickedFile;
  DateTime? _birthDate;
  String _gender = 'Male';

  final String defaultImage = 'assets/images/defaulticon.png';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;

    if (_pickedFile != null) {
      imageProvider =
          kIsWeb
              ? NetworkImage(_pickedFile!.path)
              : FileImage(io.File(_pickedFile!.path)) as ImageProvider;
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_imageUrl!);
    } else {
      imageProvider = AssetImage(defaultImage);
    }

    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(radius: 60, backgroundImage: imageProvider),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _usernameCTRL,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
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
            TextFormField(
              controller: _ageCTRL,
              readOnly: true,
              decoration: InputDecoration(
                hintText: "Enter Age",
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              onTap: () async {
                final age = await showDialog<int>(
                  context: context,
                  builder: (context) {
                    final TextEditingController tempAgeCtrl =
                        TextEditingController();
                    return AlertDialog(
                      title: Text('Enter your age'),
                      content: TextField(
                        controller: tempAgeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(hintText: 'Enter age'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                              int.tryParse(tempAgeCtrl.text),
                            );
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );

                if (age != null && age > 0) {
                  DateTime birthDate = _birthDateFromAge(age);
                  setState(() {
                    _birthDate = birthDate;
                    _ageCTRL.text = age.toString();
                  });
                }
              },
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _gender,
              items:
                  ['Male', 'Female'].map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _gender = value!;
                });
              },
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _heightCTRL,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 20.0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _weightCTRL,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 20.0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 43,
              child: ElevatedButton(
                onPressed: saveChanges,
                child: Text(
                  "Save Changes",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 43,
              child: ElevatedButton(
                onPressed: deleteAccount,
                child: Text(
                  "Delete Account",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data()!;
    setState(() {
      _usernameCTRL.text = data['username'] ?? '';
      _gender = data['gender'] ?? 'Male';
      _ageCTRL.text = data['age'].toString();
      if (data['birthDate'] != null) {
        _birthDate = (data['birthDate'] as Timestamp).toDate();
        _ageCTRL.text = _calculateAge(_birthDate!).toString();
      }
      _heightCTRL.text = data['height'].toString();
      _weightCTRL.text = data['weight'].toString();
      _imageUrl = data['image'] ?? '';
    });
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedFile = picked;
      });
    }
  }

  Future<void> saveChanges() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    String? imageUrl = _imageUrl;

    if (_birthDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your age')));
      return;
    }

    int age = _calculateAge(_birthDate!);

    if (_pickedFile != null) {
      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/$uid.jpg',
      );

      if (kIsWeb) {
        final bytes = await _pickedFile!.readAsBytes();
        await ref.putData(bytes);
      } else {
        final file = io.File(_pickedFile!.path);
        await ref.putFile(file);
      }

      imageUrl = await ref.getDownloadURL();

      // 🔄 Update imageUrl in local state so the new profile picture displays
      setState(() {
        _imageUrl = imageUrl;
        _pickedFile = null; // Optional: Clear selected file after upload
      });
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'username': _usernameCTRL.text,
      'gender': _gender,
      'age': age,
      'birthDate': _birthDate,
      'image': imageUrl,
      'height': _heightCTRL.text,
      'weight': _weightCTRL.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;

      // Step 1: Delete profile image from Firebase Storage
      try {
        final ref = FirebaseStorage.instance.ref().child(
          'profile_images/$uid.jpg',
        );
        await ref.delete();
      } catch (e) {
        print("Image deletion skipped or failed: $e"); // Optional error log
      }

      // Step 2: Delete user document from Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // Step 3: Delete Firebase Auth account
      await user.delete();

      // Step 4: Show confirmation and redirect
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.red,
        ),
      );

      Navigator.of(
        context,
      ).popUntil((route) => route.isFirst); // Go back to login or home page
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in again to delete your account'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
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

  DateTime _birthDateFromAge(int age) {
    final now = DateTime.now();
    return DateTime(now.year - age, now.month, now.day);
  }
}
