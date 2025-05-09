import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddMeal extends StatefulWidget {
  final String mealName;
  final Map<String, dynamic>? apiData;

  const AddMeal({
    super.key,
    required this.mealName,
    this.apiData,
  });

  @override
  State<AddMeal> createState() => _AddMealState();
}

class _AddMealState extends State<AddMeal> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  XFile? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadApiData();
  }

  void _loadApiData() {
    if (widget.apiData != null) {
      _caloriesController.text = widget.apiData!['calories']?.toString() ?? '';
      _carbsController.text = widget.apiData!['carbs']?.toString() ?? '';
      _proteinController.text = widget.apiData!['protein']?.toString() ?? '';
      _imageUrl = widget.apiData!['strMealThumb'];
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('meal')
          .child('${widget.mealName.toLowerCase().replaceAll(' ', '_')}.png');
      
      final bytes = await _imageFile!.readAsBytes();
      await storageRef.putData(bytes);
      
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get the latest meal ID
      final mealsSnapshot = await FirebaseFirestore.instance
          .collection('Meals')
          .orderBy('id', descending: true)
          .limit(1)
          .get();

      String newId = 'M001';
      if (mealsSnapshot.docs.isNotEmpty) {
        final lastId = mealsSnapshot.docs.first.data()['id'] as String;
        final number = int.parse(lastId.substring(1)) + 1;
        newId = 'M${number.toString().padLeft(3, '0')}';
      }

      // Upload image if selected
      String? imageUrl = _imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
      }

      final mealData = {
        'id': newId,
        'title': widget.mealName,
        'calories': double.parse(_caloriesController.text),
        'carbs': double.parse(_carbsController.text),
        'protein': double.parse(_proteinController.text),
        'imageUrl': imageUrl,
        'userId': user.uid,
        'isCustom': true,
      };

      // Create new meal document
      await FirebaseFirestore.instance
          .collection('Meals')
          .doc(newId)
          .set(mealData);

      if (mounted) {
        // Go back to previous page in history
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal added successfully!')),
        );
      }
    } catch (e) {
      print('Error saving meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding meal')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Meal'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          if (_imageFile != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _imageFile!.path,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (_imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _imageUrl!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Add Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.mealName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calories',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter calories' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Carbs (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter carbs' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter protein' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveMeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Add Meal',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    super.dispose();
  }
} 