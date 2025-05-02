import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic>? userData;
  int _selectedIndex = 3;

  final String defaultImage = 'assets/images/defaulticon.png';

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final imageUrl = userData!['image'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text("Profile"), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Stack(
              fit: StackFit.loose,
              alignment: AlignmentDirectional.center,
              children: [
                Container(
                  width: 300,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2.0),
                    shape: BoxShape.rectangle,
                  ),
                  child: Image.network(
                    imageUrl.isEmpty ? defaultImage : imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Column(
              children: [
                Text(
                  userData!['username'] ?? '',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('@' + (userData!['username'] ?? '')),
              ],
            ),
            SizedBox(height: 50),
            Column(
              children: [
                infoTile(Icons.email, userData!['email'] ?? ''),
                SizedBox(height: 35),
                infoTile(Icons.male, userData!['gender'] ?? ''),
                SizedBox(height: 35),
                infoTile(Icons.cake, userData!['age'].toString()),
                SizedBox(height: 35),
              ],
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    height: 43,
                    child: ElevatedButton(
                      onPressed:
                          () => Navigator.pushNamed(context, '/edit_profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 43,
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        "Log Out",
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
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Food'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget infoTile(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 5),
      child: Row(
        children: [
          Icon(icon),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        userData = doc.data();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigate to other pages
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushNamed(context, '/progress');
        break;
      case 2:
        Navigator.pushNamed(context, '/food');
        break;
      case 3:
        break; // already on profile
    }
  }
}
