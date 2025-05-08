import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class MealService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Map<String, dynamic> _mergeMealData(Map<String, dynamic> original, Map<String, dynamic> custom) {
    final merged = Map<String, dynamic>.from(original);
    
    final customFields = [
      'calories',
      'carbs',
      'protein',
      'fat',
      'imageUrl',
      'title',
      'strMeal',
      'strInstructions',
    ];

    for (var field in customFields) {
      if (custom.containsKey(field) && custom[field] != null) {
        merged[field] = custom[field];
      }
    }

    return merged;
  }

  // Get a meal with custom data if available
  static Future<Map<String, dynamic>?> getMeal(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final mealDoc = await _firestore.collection('Meals').doc(id).get();
      if (!mealDoc.exists) return null;

      var mealData = mealDoc.data()!;

      final customDataDoc = await _firestore
          .collection('Meals')
          .doc(id)
          .collection(user.uid)
          .doc('data')
          .get();

      if (customDataDoc.exists) {
        mealData = _mergeMealData(mealData, customDataDoc.data()!);
      }

      return mealData;
    } catch (e) {
      print('Error getting meal: $e');
      return null;
    }
  }

  // Get all meals with custom data if available
  static Future<List<Map<String, dynamic>>> getAllMeals({int limit = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('Meals')
          .orderBy('id')
          .limit(limit)
          .get();

      List<Map<String, dynamic>> meals = [];
      
      for (var doc in snapshot.docs) {
        var mealData = doc.data();
        
        final customDataDoc = await _firestore
            .collection('Meals')
            .doc(doc.id)
            .collection(user.uid)
            .doc('data')
            .get();

        if (customDataDoc.exists) {
          mealData = _mergeMealData(mealData, customDataDoc.data()!);
        }
        
        meals.add(mealData);
      }

      return meals;
    } catch (e) {
      print('Error getting all meals: $e');
      return [];
    }
  }

  // Get default meal data without custom data
  static Future<Map<String, dynamic>?> getDefaultMeal(String id) async {
    try {
      final doc = await _firestore.collection('Meals').doc(id).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting default meal: $e');
      return null;
    }
  }

  // Get all default meals without custom data
  static Future<List<Map<String, dynamic>>> getAllDefaultMeals({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('Meals')
          .orderBy('id')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data())
          .where((meal) => meal != null)
          .toList();
    } catch (e) {
      print('Error getting all default meals: $e');
      return [];
    }
  }

  static Future<String> addMeal({
    required String title,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    File? imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    String? imageUrl;
    if (imageFile != null) {
      final storageRef = _storage.ref().child('meals/${user.uid}/${DateTime.now().millisecondsSinceEpoch}');
      await storageRef.putFile(imageFile);
      imageUrl = await storageRef.getDownloadURL();
    }

    final mealRef = _firestore.collection('Meal').doc();
    await mealRef.set({
      'title': title,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'imageUrl': imageUrl,
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return mealRef.id;
  }

  static Future<List<Map<String, dynamic>>> getAllMeals() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('Meal')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<void> updateMeal({
    required String mealId,
    required String title,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    File? imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final mealDoc = await _firestore.collection('Meal').doc(mealId).get();
    if (!mealDoc.exists || mealDoc.data()?['userId'] != user.uid) {
      throw Exception('Meal not found or unauthorized');
    }

    String? imageUrl;
    if (imageFile != null) {
      final storageRef = _storage.ref().child('meals/${user.uid}/${DateTime.now().millisecondsSinceEpoch}');
      await storageRef.putFile(imageFile);
      imageUrl = await storageRef.getDownloadURL();
    }

    await _firestore.collection('Meal').doc(mealId).update({
      'title': title,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteMeal(String mealId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final mealDoc = await _firestore.collection('Meal').doc(mealId).get();
    if (!mealDoc.exists || mealDoc.data()?['userId'] != user.uid) {
      throw Exception('Meal not found or unauthorized');
    }

    await _firestore.collection('Meal').doc(mealId).delete();
  }
}