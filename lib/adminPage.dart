import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class adminPage extends StatefulWidget {
  const adminPage({super.key});

  @override
  State<adminPage> createState() => _adminPageState();
}

class _adminPageState extends State<adminPage> {
  late final String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          // Filter out current admin's own account
          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUserId)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('No other users found.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final username = user['username'] ?? 'No name';
              final email = user['email'] ?? 'No email';
              final isAdmin = user['isAdmin'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(username),
                  subtitle: Text(email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isAdmin,
                        onChanged: (bool value) async {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.id)
                              .update({'isAdmin': value});
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Confirm Deletion'),
                              content: Text(
                                  'Are you sure you want to delete this user? This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.id)
                                .delete();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('User deleted successfully'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
