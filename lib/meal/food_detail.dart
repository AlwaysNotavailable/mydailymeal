import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_meal.dart';
import 'meal_service.dart';
import 'MealHistoryService.dart';

class FoodDetail extends StatefulWidget {
  final Map<String, dynamic> meal;
  final String selectedFilter;

  const FoodDetail({
    super.key,
    required this.meal,
    required this.selectedFilter,
  });

  @override
  State<FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<FoodDetail> {
  bool _isLoading = false;
  Map<String, dynamic>? _userCustomData;

  @override
  void initState() {
    super.initState();
    _loadUserCustomData();
  }

  Future<void> _loadUserCustomData() async {
    try {
      final mealData = await MealService.getMeal(widget.meal['id']);
      if (mealData != null) {
        setState(() {
          _userCustomData = mealData;
        });
      }
    } catch (e) {
      print('Error loading user custom data: $e');
    }
  }

  Future<void> _editMeal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMeal(
          meal: _userCustomData ?? widget.meal,
        ),
      ),
    );

    if (result == true) {
      _loadUserCustomData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use user custom data if available, otherwise use original meal data
    final displayData = _userCustomData ?? widget.meal;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(displayData['title'] ?? displayData['strMeal'] ?? 'Meal Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editMeal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayData['imageUrl'] != null || displayData['strMealThumb'] != null)
                    Image.network(
                      displayData['imageUrl'] ?? displayData['strMealThumb'],
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayData['title'] ?? displayData['strMeal'] ?? 'Unknown Meal',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildNutritionInfo('Calories', '${displayData['calories'] ?? 'N/A'} cal'),
                        _buildNutritionInfo('Carbs', '${displayData['carbs'] ?? 'N/A'}g'),
                        _buildNutritionInfo('Protein', '${displayData['protein'] ?? 'N/A'}g'),
                        if (displayData['fat'] != null)
                          _buildNutritionInfo('Fat', '${displayData['fat']}g'),
                        const SizedBox(height: 24),
                        if (displayData['strInstructions'] != null) ...[
                          const Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(displayData['strInstructions']),
                        ],
                        const SizedBox(height: 24),
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
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _addToMeal('breakfast'),
                                icon: const Icon(Icons.wb_sunny_outlined),
                                label: const Text('Breakfast'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[100],
                                  foregroundColor: Colors.orange[900],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _addToMeal('lunch'),
                                icon: const Icon(Icons.restaurant),
                                label: const Text('Lunch'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[100],
                                  foregroundColor: Colors.green[900],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _addToMeal('dinner'),
                                icon: const Icon(Icons.nightlight_round),
                                label: const Text('Dinner'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[100],
                                  foregroundColor: Colors.blue[900],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
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

  Widget _buildNutritionInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _addToMeal(String collection) async {
    setState(() => _isLoading = true);
    try {
      final result = await MealHistoryService.addToHistory(
        widget.meal['id'],
        collection,
      );

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to $collection successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add to $collection'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding to $collection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to $collection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
} 