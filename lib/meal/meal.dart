import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'food_detail.dart';

class MealPage extends StatefulWidget {
  const MealPage({super.key});

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _meals = [];
  List<Map<String, dynamic>> _filteredMeals = [];
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _caloriesController = TextEditingController();
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
          
          // Extract nutritional information
          double calories = 0;
          double protein = 0;
          double carbs = 0;
          double fat = 0;

          for (var nutrient in nutrients) {
            final nutrientId = nutrient['nutrientId'];
            final value = nutrient['value'] ?? 0.0;

            switch (nutrientId) {
              case 1008: // Energy (kcal)
                calories = value;
                break;
              case 1003: // Protein
                protein = value;
                break;
              case 1005: // Carbohydrates
                carbs = value;
                break;
              case 1004: // Total fat
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
      // First, try to fetch from Firebase
      final mealsSnapshot = await FirebaseFirestore.instance
          .collection('Meals')
          .get();

      List<Map<String, dynamic>> meals = [];
      
      if (mealsSnapshot.docs.isNotEmpty) {
        meals = mealsSnapshot.docs
            .map((doc) {
              final data = doc.data();
              if (data != null && data['data'] != null) {
                return data['data'] as Map<String, dynamic>;
              }
              return null;
            })
            .where((meal) => meal != null)
            .cast<Map<String, dynamic>>()
            .toList();
        
        print('Fetched ${meals.length} meals from Firebase');
      }

      // If we have less than 20 meals or no meals at all, fetch from TheMealDB
      if (meals.length < 20) {
        print('Fetching from TheMealDB API...');
        // Fetch multiple random meals
        for (int i = 0; i < 20; i++) {
          try {
            final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php'));
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              if (data != null && data['meals'] != null && data['meals'].isNotEmpty) {
                final apiMeal = data['meals'][0] as Map<String, dynamic>;
                if (apiMeal != null) {
                  print('Fetched random meal: ${apiMeal['strMeal']}');
                  
                  // Get nutritional information from USDA API
                  final nutritionInfo = await _getNutritionalInfo(apiMeal['strMeal']);
                  apiMeal.addAll(nutritionInfo);
                  
                  // Add only if it doesn't already exist
                  if (!meals.any((meal) => 
                    (meal['strMeal'] == apiMeal['strMeal']) || 
                    (meal['title'] == apiMeal['strMeal']))) {
                    meals.add(apiMeal);
                  }
                }
              }
            }
          } catch (e) {
            print('Error fetching random meal: $e');
            continue;
          }
          // Add a small delay to avoid hitting rate limits
          await Future.delayed(const Duration(milliseconds: 100));
        }
        print('Fetched ${meals.length} meals from API');
      }

      // Fetch custom meals from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final customMealsSnapshot = await FirebaseFirestore.instance
              .collection('custom_meals')
              .where('userId', isEqualTo: user.uid)
              .get();

          final customMeals = customMealsSnapshot.docs
              .map((doc) => doc.data())
              .where((meal) => meal != null)
              .toList();

          print('Fetched ${customMeals.length} custom meals');
          meals.addAll(customMeals);
        } catch (e) {
          print('Error fetching custom meals: $e');
        }
      }

      print('Total meals: ${meals.length}');
      setState(() {
        _meals = meals;
        _filteredMeals = meals;
      });
    } catch (e) {
      print('Error fetching meals: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterMeals(String query) {
    setState(() {
      _filteredMeals = _meals
          .where((meal) =>
              meal['strMeal']?.toString().toLowerCase().contains(query.toLowerCase()) ??
              meal['title']?.toString().toLowerCase().contains(query.toLowerCase()) ??
              false)
          .toList();
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('custom_meals')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    await storageRef.putFile(_imageFile!);
    return await storageRef.getDownloadURL();
  }

  Future<void> _addCustomMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
      }

      final customMeal = {
        'title': _titleController.text,
        'calories': int.parse(_caloriesController.text),
        'imageUrl': imageUrl,
        'userId': user.uid,
        'isCustom': true,
      };

      await FirebaseFirestore.instance
          .collection('custom_meals')
          .add(customMeal);

      setState(() {
        _meals.add(customMeal);
        _filteredMeals = _meals;
      });

      _titleController.clear();
      _caloriesController.clear();
      _imageFile = null;
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom meal added successfully!')),
        );
      }
    } catch (e) {
      print('Error adding custom meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding custom meal')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddCustomMealDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Meal'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Meal Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),
                TextFormField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(labelText: 'Calories'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter calories' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Pick Image'),
                ),
                if (_imageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Image.file(
                      _imageFile!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addCustomMeal,
            child: const Text('Add'),
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
                : ListView.builder(
                    itemCount: _filteredMeals.length,
                    itemBuilder: (context, index) {
                      final meal = _filteredMeals[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              meal['strMealThumb'] ?? meal['imageUrl'] ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.fastfood, size: 60),
                            ),
                          ),
                          title: Text(
                            meal['strMeal'] ?? meal['title'] ?? 'Unknown Meal',
                          ),
                          subtitle: Text(
                            '${meal['calories'] ?? 'N/A'} calories',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FoodDetail(
                                  meal: meal,
                                  selectedFilter: 'Today',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
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

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }
} 