import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'EditConsumedMeal.dart';

class ConsumedMeal extends StatefulWidget {
  final String filter;
  final String mealType; // e.g., 'breakfast', 'lunch', 'dinner'

  const ConsumedMeal({super.key, required this.filter, required this.mealType});

  @override
  State<ConsumedMeal> createState() => _ConsumedMealState();
}

class _ConsumedMealState extends State<ConsumedMeal> {
  List<MealItem> meals = [];
  List<bool> selected = [];

  String getAppBarTitle() {
    String meal =
        widget.mealType[0].toUpperCase() + widget.mealType.substring(1);
    switch (widget.filter) {
      case 'Today':
        return '$meal Consumed Today';
      case 'This Month':
        return '$meal Consumed This Month';
      case 'This Year':
        return '$meal Consumed This Year';
      case 'Overall':
        return '$meal Consumed Overall';
      default:
        return '$meal Log';
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

    final snapshot =
        await FirebaseFirestore.instance
            .collection('consumedMeals')
            .doc(uid)
            .collection(widget.mealType)
            .get();

    List<MealItem> fetchedMeals = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final Timestamp? timestamp = data['date'];
      final docDate = timestamp?.toDate();

      if (docDate != null && isMatchingFilter(docDate)) {
        final mealId = data['mealId'];
        if (mealId != null) {
          final mealSnapshot =
              await FirebaseFirestore.instance
                  .collection('Meals')
                  .doc(mealId)
                  .get();

          if (mealSnapshot.exists) {
            final mealData = mealSnapshot.data()!;
            fetchedMeals.add(
              MealItem(
                id: doc.id,
                title: mealData['title'] ?? 'No title',
                calories: '${data['calories'] ?? 0}cal',
                carbs: '${data['carbs'] ?? 0}g',
                protein: '${data['protein'] ?? 0}g',
                imageUrl: mealData['imageUrl'] ?? '',
              ),
            );
          }
        }
      }
    }

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
          onPressed: () => Navigator.pop(context, true),
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
                  children: [
                    const Spacer(),
                    Text(
                      "Oops! No ${widget.mealType[0].toUpperCase()}${widget.mealType.substring(1)} meals found. Please try changing the filter and try again.",
                      style: const TextStyle(
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
                            title: Text(meals[index].title),
                            subtitle: Text(
                              'Calories: ${meals[index].calories} , Carbs: ${meals[index].carbs} , Protein: ${meals[index].protein}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final currentUser =
                                        FirebaseAuth.instance.currentUser;
                                    if (currentUser == null) return;

                                    final uid = currentUser.uid;
                                    final consumedMealRef = FirebaseFirestore
                                        .instance
                                        .collection('consumedMeals')
                                        .doc(uid)
                                        .collection(widget.mealType)
                                        .doc(meals[index].id);

                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => EditConsumedMeal(
                                              consumedMealRef: consumedMealRef,
                                              mealId: meals[index].id,
                                              mealType: widget.mealType,
                                            ),
                                      ),
                                    );

                                    if (result == true) {
                                      fetchMeals(); // Refresh
                                    }
                                  },
                                ),
                                Checkbox(
                                  value: selected[index],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      selected[index] = value ?? false;
                                    });
                                  },
                                ),
                              ],
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

                              final uid =
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (uid == null) return;

                              for (var index in selectedIndexes) {
                                final mealId = meals[index].id;
                                await FirebaseFirestore.instance
                                    .collection('consumedMeals')
                                    .doc(uid)
                                    .collection(widget.mealType)
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
  final String title;
  final String calories;
  final String carbs;
  final String protein;
  final String imageUrl;

  MealItem({
    required this.id,
    required this.title,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.imageUrl,
  });
}
