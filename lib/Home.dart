import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Breakfast.dart';
import 'Lunch.dart';
import 'Dinner.dart';
import 'IdealWeight.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  // Example pages for other tabs (optional placeholders)
  static const List<Widget> _widgetOptions = <Widget>[
    Center(child: Text('Home Page')),
    SizedBox.shrink(), // Progress will trigger navigation instead
    Center(child: Text('Food Page')),
    Center(child: Text('Profile Page')),
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      // Progress tapped, navigate to IdealWeight page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => IdealWeight()),
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
      final snapshot = await FirebaseFirestore.instance
          .collection('consumedMeals')
          .doc(uid)
          .collection(meal) // subcollection also named 'breakfast', 'lunch', or 'dinner'
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final mealName = meal[0].toUpperCase() + meal.substring(1); // Capitalize
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
                      if (title == 'Breakfast') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Breakfast(filter: selectedFilter),
                          ),
                        );
                        if (result == true) {
                          fetchData(); // Refresh home page after returning from Breakfast page
                        }
                      } else if (title == 'Lunch') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => Lunch(filter: selectedFilter),
                          ),
                        );
                        if (result == true) {
                          fetchData(); // Refresh home page after returning from Breakfast page
                        }
                      } else if (title == 'Dinner') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => Dinner(filter: selectedFilter),
                          ),
                        );
                        if (result == true) {
                          fetchData(); // Refresh home page after returning from Breakfast page
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No page for $title yet!'),
                          ),
                        );
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
                  // Add meal logic
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Food',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
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
