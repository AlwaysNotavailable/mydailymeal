import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditConsumedMeal extends StatefulWidget {
  final DocumentReference consumedMealRef;
  final String mealId;
  final String mealType;

  const EditConsumedMeal({
    super.key,
    required this.consumedMealRef,
    required this.mealId,
    required this.mealType,
  });

  @override
  State<EditConsumedMeal> createState() => _EditConsumedMealState();
}

class _EditConsumedMealState extends State<EditConsumedMeal> {
  TextEditingController caloriesController = TextEditingController();
  TextEditingController carbsController = TextEditingController();
  TextEditingController proteinController = TextEditingController();

  String title = '';
  String imageUrl = '';

  @override
  void initState() {
    super.initState();
    loadMealData();
  }

  Future<void> loadMealData() async {
    final consumedMealSnap = await widget.consumedMealRef.get();
    final consumedData = consumedMealSnap.data() as Map<String, dynamic>?;

    if (consumedData == null) return;

    final mealId = consumedData['mealId'];
    final mealSnap = await FirebaseFirestore.instance
        .collection('Meals')
        .doc(mealId)
        .get();
    final mealData = mealSnap.data();

    setState(() {
      title = mealData?['title'] ?? '';
      imageUrl = mealData?['imageUrl'] ?? '';
      caloriesController.text = consumedData['calories'].toString();
      carbsController.text = consumedData['carbs'].toString();
      proteinController.text = consumedData['protein'].toString();
    });
  }

  Future<void> saveChanges() async {
    await widget.consumedMealRef.update({
      'calories': int.tryParse(caloriesController.text) ?? 0,
      'carbs': int.tryParse(carbsController.text) ?? 0,
      'protein': int.tryParse(proteinController.text) ?? 0,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meal updated successfully')),
    );
    Navigator.pop(context, true);
  }

  Future<void> deleteMeal() async {
    await widget.consumedMealRef.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meal deleted successfully')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true, // This centers the title
        title: Text(
          'Edit ${widget.mealType[0].toUpperCase()}${widget.mealType.substring(1)} Data Page',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl, height: 160),
            const SizedBox(height: 16),
            Text('Title: $title', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              decoration: const InputDecoration(labelText: 'Calories'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: carbsController,
              decoration: const InputDecoration(labelText: 'Carbs'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: proteinController,
              decoration: const InputDecoration(labelText: 'Protein'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Center(child: Text('Save')),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: deleteMeal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Center(child: Text('Delete')),
            ),
          ],
        ),
      ),
    );
  }
}
