import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'food_detail.dart';
import 'add_meal.dart';
import 'meal_service.dart';

class MealPage extends StatefulWidget {
  const MealPage({super.key});

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _databaseMeals = [];
  List<Map<String, dynamic>> _apiMeals = [];
  List<Map<String, dynamic>> _filteredDatabaseMeals = [];
  List<Map<String, dynamic>> _filteredApiMeals = [];
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _fetchMeals();
  }

  Future<Map<String, dynamic>> _getNutritionalInfo(String foodName) async {
    try {
      const apiKey = 'i9zJS4WkDAnXqmpcdJ0ObCJkKjigUKkdoCsbXusH';
      
      final response = await http.get(
        Uri.parse('https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$apiKey&query=$foodName&pageSize=1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['foods'] != null && data['foods'].isNotEmpty) {
          final food = data['foods'][0];
          final nutrients = food['foodNutrients'] as List;
          
          double calories = 0;
          double protein = 0;
          double carbs = 0;
          double fat = 0;

          for (var nutrient in nutrients) {
            final nutrientId = nutrient['nutrientId'];
            final value = nutrient['value'] ?? 0.0;

            switch (nutrientId) {
              case 1008:
                calories = value;
                break;
              case 1003:
                protein = value;
                break;
              case 1005:
                carbs = value;
                break;
              case 1004:
                fat = value;
                break;
            }
          }

          return {
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
          };
        }
      } else if (response.statusCode == 403) {
        print('Error: Invalid or missing API key');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Please configure your USDA API key'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching nutritional info: $e');
    }
    return {
      'calories': 0,
      'protein': 0,
      'carbs': 0,
      'fat': 0,
    };
  }

  Future<void> _fetchMeals() async {
    setState(() => _isLoading = true);
    try {
      // First fetch Firebase data
      _databaseMeals = await MealService.getAllMeals();
      print('Fetched ${_databaseMeals.length} meals from Firebase');
      setState(() {
        _filteredDatabaseMeals = _databaseMeals;
        _isLoading = false; // Set loading to false after Firebase data is loaded
      });

      // Then fetch API data in the background
      List<Map<String, dynamic>> apiMeals = [];
      for (int i = 0; i < 10; i++) {
        try {
          final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php'));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data != null && data['meals'] != null && data['meals'].isNotEmpty) {
              final apiMeal = data['meals'][0] as Map<String, dynamic>;
              if (apiMeal != null) {
                print('Fetched random meal: ${apiMeal['strMeal']}');
                
                final nutritionInfo = await _getNutritionalInfo(apiMeal['strMeal']);
                apiMeal.addAll(nutritionInfo);
                
                if (!apiMeals.any((meal) => 
                  (meal['strMeal'] == apiMeal['strMeal']) || 
                  (meal['title'] == apiMeal['strMeal']))) {
                  apiMeals.add(apiMeal);
                  
                  if (mounted) {
                    setState(() {
                      _apiMeals = apiMeals;
                      _filteredApiMeals = apiMeals;
                    });
                  }
                }
              }
            }
          }
        } catch (e) {
          print('Error fetching random meal: $e');
          continue;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
      print('Fetched ${apiMeals.length} meals from API');
    } catch (e) {
      print('Error fetching meals: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterMeals(String query) {
    setState(() {
      _filteredDatabaseMeals = _databaseMeals
          .where((meal) =>
              meal['strMeal']?.toString().toLowerCase().contains(query.toLowerCase()) ??
              meal['title']?.toString().toLowerCase().contains(query.toLowerCase()) ??
              false)
          .toList();
      
      _filteredApiMeals = _apiMeals
          .where((meal) =>
              meal['strMeal']?.toString().toLowerCase().contains(query.toLowerCase()) ??
              meal['title']?.toString().toLowerCase().contains(query.toLowerCase()) ??
              false)
          .toList();
    });
  }

  void _showAddCustomMealDialog() {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Meal'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Meal Name',
            hintText: 'Enter the name of the meal',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMeal(
                      mealName: nameController.text,
                    ),
                  ),
                ).then((success) {
                  if (success == true) {
                    _fetchMeals();
                  }
                });
              }
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meals'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search meals...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterMeals,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      if (_filteredDatabaseMeals.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Your Meals',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._filteredDatabaseMeals.map((meal) => _buildMealCard(meal)),
                      ],
                      if (_filteredApiMeals.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Suggested Meals',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._filteredApiMeals.map((meal) => _buildMealCard(meal)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomMealDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Custom Food'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final displayData = meal;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            displayData['strMealThumb'] ?? displayData['imageUrl'] ?? '',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.fastfood, size: 60),
          ),
        ),
        title: Text(
          displayData['strMeal'] ?? displayData['title'] ?? 'Unknown Meal',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calories: ${displayData['calories'] ?? 'N/A'} cal',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Carbs: ${displayData['carbs'] ?? 'N/A'}g | Protein: ${displayData['protein'] ?? 'N/A'}g',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodDetail(
                meal: displayData,
                selectedFilter: 'Today',
              ),
            ),
          );
          
          // Refresh meals if we're returning from FoodDetail
          if (result == true) {
            _fetchMeals();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    super.dispose();
  }
} 