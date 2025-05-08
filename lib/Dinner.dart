import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:firebase_auth/firebase_auth.dart';

class Dinner extends StatefulWidget {
  final String filter;

  const Dinner({super.key, required this.filter});

  @override
  State<Dinner> createState() => _DinnerState();
}

class _DinnerState extends State<Dinner> {
  List<MealItem> meals = [];
  List<bool> selected = [];

  String getAppBarTitle() {
    switch (widget.filter) {
      case 'Today':
        return 'Dinner Consumed Today';
      case 'This Month':
        return 'Dinner Consumed This Month';
      case 'This Year':
        return 'Dinner Consumed This Year';
      case 'Overall':
        return 'Dinner Consumed Overall';
      default:
        return 'Dinner Log';
    }
  }

  bool isMatchingFilter(DateTime docDate) {
    final now = DateTime.now();

    switch (widget.filter) {
      case 'Today':
        return docDate.year == now.year &&
            docDate.month == now.month &&
            docDate.day == now.day;
      case 'This Month':
        return docDate.year == now.year && docDate.month == now.month;
      case 'This Year':
        return docDate.year == now.year;
      case 'Overall':
        return true;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMeals();
  }

  Future<void> fetchMeals() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final uid = currentUser.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('dinner')
        .where('user', isEqualTo: uid)
        .get();
    final now = DateTime.now();

    final fetchedMeals = snapshot.docs.map((doc) {
      final data = doc.data();
      final Timestamp? timestamp = data['date'];
      final docDate = timestamp?.toDate();

      if (docDate != null && isMatchingFilter(docDate)) {
        return MealItem(
          id: doc.id,
          name: data['name'] ?? 'No name',
          calories: '${data['calories'] ?? 0}cal',
          carbs: '${data['carbs'] ?? 0}g',
          protein: '${data['protein'] ?? 0}g',
          imageUrl: data['photo'] ?? '',
        );
      }
      return null;
    }).whereType<MealItem>().toList();

    setState(() {
      meals = fetchedMeals;
      selected = List.filled(meals.length, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          getAppBarTitle(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
        meals.isEmpty
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            const Text(
              "Oops! No dinner items found. Please try changing the filter and try again.",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Add Meal logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Meal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
          ],
        )
            : Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        meals[index].imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(meals[index].name),
                    subtitle: Text(
                      'Calories: ${meals[index].calories} , Carbs: ${meals[index].carbs} , Protein: ${meals[index].protein}',
                    ),
                    trailing: Checkbox(
                      value: selected[index],
                      onChanged: (bool? value) {
                        setState(() {
                          selected[index] = value ?? false;
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        selected[index] = !selected[index];
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Add Meal logic
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final selectedIndexes =
                      selected
                          .asMap()
                          .entries
                          .where((entry) => entry.value)
                          .map((entry) => entry.key)
                          .toList();

                      if (selectedIndexes.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "You haven't selected any meal checkbox yet. Please try again!",
                            ),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      for (var index in selectedIndexes) {
                        final mealId = meals[index].id;
                        await FirebaseFirestore.instance
                            .collection('dinner')
                            .doc(mealId)
                            .delete();
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully Deleted'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );

                      // Refresh the UI
                      fetchMeals();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MealItem {
  final String id;
  final String name;
  final String calories;
  final String carbs;
  final String protein;
  final String imageUrl;

  MealItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.imageUrl,
  });
}
