import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditMeal extends StatefulWidget {
  final Map<String, dynamic> meal;

  const EditMeal({
    super.key,
    required this.meal,
  });

  @override
  State<EditMeal> createState() => _EditMealState();
}

class _EditMealState extends State<EditMeal> {
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _hasCustomData = false;
  final _formKey = GlobalKey<FormState>();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  XFile? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadMealData();
    _checkAdminStatus();
    _checkCustomData();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _isAdmin = userDoc.data()?['isAdmin'] ?? false;
      });
      print('Admin status: $_isAdmin');
    }
  }

  Future<void> _checkCustomData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final customDataDoc = await FirebaseFirestore.instance
          .collection('Meals')
          .doc(widget.meal['id'])
          .collection(user.uid)
          .doc('data')
          .get();

      setState(() {
        _hasCustomData = customDataDoc.exists;
      });
      print('Has custom data: $_hasCustomData');
    } catch (e) {
      print('Error checking custom data: $e');
    }
  }

  void _loadMealData() {
    _caloriesController.text = widget.meal['calories']?.toString() ?? '';
    _carbsController.text = widget.meal['carbs']?.toString() ?? '';
    _proteinController.text = widget.meal['protein']?.toString() ?? '';
    _imageUrl = widget.meal['imageUrl'] ?? widget.meal['strMealThumb'];
    setState(() => _isLoading = false);
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Create unique filename using meal title and user ID
      final mealTitle = widget.meal['title']?.toLowerCase().replaceAll(' ', '_') ?? 'meal';
      final fileName = '${mealTitle}_${user.uid}.png';
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('meal')
          .child(fileName);
      
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

      // Upload image if selected
      String? imageUrl = _imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
      }

      final mealData = {
        'id': widget.meal['id'],
        'title': widget.meal['title'] ?? widget.meal['strMeal'],
        'calories': double.parse(_caloriesController.text),
        'carbs': double.parse(_carbsController.text),
        'protein': double.parse(_proteinController.text),
        'imageUrl': imageUrl,
        'userId': user.uid,
        'isCustom': true,
        'originalImageUrl': widget.meal['strMealThumb'], // Store original image URL
      };

      // Save to user's collection with 'data' document
      await FirebaseFirestore.instance
          .collection('Meals')
          .doc(widget.meal['id'])
          .collection(user.uid)
          .doc('data')
          .set(mealData);

      if (mounted) {
        // Go back to previous page in history with success result
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal updated successfully!')),
        );
      }
    } catch (e) {
      print('Error saving meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating meal')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMeal(bool deleteAll) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (deleteAll) {
        // Delete from all users' collections
        final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
        for (var userDoc in usersSnapshot.docs) {
          await FirebaseFirestore.instance
              .collection('Meals')
              .doc(widget.meal['id'])
              .collection(userDoc.id)
              .doc('data')
              .delete();
        }
      } else {
        // Delete only from current user's collection
        await FirebaseFirestore.instance
            .collection('Meals')
            .doc(widget.meal['id'])
            .collection(user.uid)
            .doc('data')
            .delete();
      }

      if (mounted) {
        // Return true to trigger refresh in meal page
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deleteAll 
              ? 'Meal deleted for all users successfully!'
              : 'Your custom data deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting meal')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(bool deleteAll) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deleteAll ? 'Delete for All Users' : 'Delete Custom Data'),
        content: Text(
          deleteAll
              ? 'Are you sure you want to delete this meal for all users? This will remove the meal from all users\' collections. This action cannot be undone.'
              : 'Are you sure you want to delete your custom data for this meal? This will only affect your custom version of this meal. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMeal(deleteAll);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    print('Current user: ${currentUser?.uid}');
    print('Has custom data: $_hasCustomData');
    print('Is admin: $_isAdmin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Meal'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.delete, color: Colors.red),
              onSelected: (value) {
                if (value == 'delete_custom') {
                  _showDeleteConfirmation(false);
                } else if (value == 'delete_all') {
                  _showDeleteConfirmation(true);
                }
              },
              itemBuilder: (context) => [
                if (_hasCustomData)
                  const PopupMenuItem(
                    value: 'delete_custom',
                    child: Text('Delete My Custom Data'),
                  ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Text('Delete for All Users'),
                ),
              ],
            )
          else if (_hasCustomData)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(false),
            ),
        ],
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
                            label: const Text('Change Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.meal['title'] ?? widget.meal['strMeal'] ?? 'Unknown Meal',
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
                          'Save Changes',
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