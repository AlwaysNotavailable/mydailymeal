import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodDetail extends StatelessWidget {
  final Map<String, dynamic> meal;
  final String selectedFilter;

  const FoodDetail({
    super.key,
    required this.meal,
    required this.selectedFilter,
  });

  Future<void> _addToMeal(BuildContext context, String mealType, Color buttonColor, IconData icon) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final mealData = {
      'name': meal['strMeal'] ?? meal['title'],
      'calories': meal['calories'] ?? 0,
      'imageUrl': meal['strMealThumb'] ?? meal['imageUrl'],
      'date': Timestamp.fromDate(now),
      'user': user.uid,
      'mealType': mealType,
    };

    try {
      final mealsRef = FirebaseFirestore.instance.collection('Meals');
      final lastMeal = await mealsRef
          .orderBy('id', descending: true)
          .limit(1)
          .get();

      String newId;
      if (lastMeal.docs.isEmpty) {
        newId = 'M001';
      } else {
        final lastId = lastMeal.docs.first.data()['id'] as String;
        final number = int.parse(lastId.substring(1)) + 1;
        newId = 'M${number.toString().padLeft(3, '0')}';
      }

      // Add the meal with the generated ID
      await mealsRef.doc(newId).set({
        'id': newId,
        'data': mealData,
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to $mealType'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding meal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error adding meal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMealButton(BuildContext context, String mealType, Color buttonColor, IconData icon) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => _addToMeal(context, mealType, buttonColor, icon),
        icon: Icon(icon),
        label: Text(mealType),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(meal['strMeal'] ?? meal['title'] ?? 'Food Detail'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    meal['strMealThumb'] ?? meal['imageUrl'] ?? '',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food Name
                  Text(
                    meal['strMeal'] ?? meal['title'] ?? 'Unknown Food',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Calories
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            '${meal['calories'] ?? 'N/A'} calories',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Instructions if available
                  if (meal['strInstructions'] != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meal['strInstructions'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Add to Meal Buttons
                  const Text(
                    'Add to Meal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMealButton(
                        context,
                        'Breakfast',
                        Colors.orange,
                        Icons.wb_sunny,
                      ),
                      const SizedBox(width: 8),
                      _buildMealButton(
                        context,
                        'Lunch',
                        Colors.blue,
                        Icons.restaurant,
                      ),
                      const SizedBox(width: 8),
                      _buildMealButton(
                        context,
                        'Dinner',
                        Colors.purple,
                        Icons.nightlight_round,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 