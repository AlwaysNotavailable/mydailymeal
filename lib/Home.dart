import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ConsumedMeal.dart';
import 'IdealWeight.dart';
import 'meal/meal.dart';
import 'profile.dart';
import 'adminPage.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  bool _isAdmin = false;

  // Example pages for other tabs (optional placeholders)
  static const List<Widget> _widgetOptions = <Widget>[
    Center(child: Text('Home Page')),
    SizedBox.shrink(), // Progress will trigger navigation instead
    MealPage(), // Food tab now shows MealPage
    Center(child: Text('Profile Page')),
  ];

  void _onItemTapped(int index) {
    if (_isAdmin && index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => adminPage()),
      );
      return;
    }

    if (index == 1) {
      // Progress tapped, navigate to IdealWeight page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => IdealWeight()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MealPage()),
      );
    } else if (index == 3) {
      // Profile tapped, navigate to Profile page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Profile()),
      );
    } else {
      // Update index for other tabs
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String selectedFilter = 'Today';
  Map<String, Map<String, dynamic>> meals = {
    'Breakfast': {'calories': 0, 'carbs': 0, 'protein': 0},
    'Lunch': {'calories': 0, 'carbs': 0, 'protein': 0},
    'Dinner': {'calories': 0, 'carbs': 0, 'protein': 0},
  };

  double totalCalories = 0;
  double totalCarbs = 0;
  double totalProtein = 0;

  final filters = ['Today', 'This Month', 'This Year', 'Overall'];

  @override
  void initState() {
    super.initState();
    fetchData();
    checkAdminStatus();
  }

  DateTime getStartDate() {
    final now = DateTime.now();

    switch (selectedFilter) {
      case 'This Month':
        return DateTime(now.year, now.month);
      case 'This Year':
        return DateTime(now.year);
      case 'Today':
        return DateTime(now.year, now.month, now.day);

      default:
        return DateTime(2000); // Arbitrary early date for 'Overall'
    }
  }

  void checkAdminStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc['isAdmin'] == true) {
        setState(() {
          _isAdmin = true;
        });
      }
    }
  }

  void fetchData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      totalCalories = 0;
      totalCarbs = 0;
      totalProtein = 0;
      meals.forEach((key, value) {
        meals[key] = {'calories': 0, 'carbs': 0, 'protein': 0};
      });
    });

    final startDate = getStartDate();
    final collections = ['breakfast', 'lunch', 'dinner'];

    for (final meal in collections) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('consumedMeals')
              .doc(uid)
              .collection(
                meal,
              ) // subcollection also named 'breakfast', 'lunch', or 'dinner'
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final mealName =
            meal[0].toUpperCase() + meal.substring(1); // Capitalize
        meals[mealName]!['calories'] += data['calories'] ?? 0;
        meals[mealName]!['carbs'] += data['carbs'] ?? 0;
        meals[mealName]!['protein'] += data['protein'] ?? 0;

        totalCalories += data['calories'] ?? 0;
        totalCarbs += data['carbs'] ?? 0;
        totalProtein += data['protein'] ?? 0;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: () {},
        ),
        centerTitle: true,
        title: const Text(
          'Preview',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          DropdownButton<String>(
            value: selectedFilter,
            items:
                filters.map((filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                selectedFilter = value!;
              });
              fetchData();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NutrientCard(title: 'Calories', value: '${totalCalories} cal'),
                NutrientCard(title: 'Carbs', value: '${totalCarbs}g'),
              ],
            ),
            const SizedBox(height: 16),
            NutrientCard(
              title: 'Protein',
              value: '${totalProtein}g',
              isFullWidth: true,
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Meals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children:
                    meals.keys.map((title) {
                      final meal = meals[title]!;
                      return ListTile(
                        title: Text(title),
                        subtitle: Text(
                          'Calories: ${meal['calories']}cal , Carbs: ${meal['carbs']}g carbs , Protein: ${meal['protein']}g',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final mealType =
                              title
                                  .toLowerCase(); // 'breakfast', 'lunch', or 'dinner'
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ConsumedMeal(
                                    mealType: mealType,
                                    filter: selectedFilter,
                                  ),
                            ),
                          );
                          if (result == true) {
                            fetchData(); // Refresh home page after returning from TodayMeal page
                          }
                        },
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MealPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add Meal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Food',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          if (_isAdmin)
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
}

class NutrientCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isFullWidth;

  const NutrientCard({
    super.key,
    required this.title,
    required this.value,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          isFullWidth
              ? double.infinity
              : MediaQuery.of(context).size.width / 2 - 24,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
