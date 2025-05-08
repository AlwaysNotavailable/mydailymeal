import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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
}