import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'meal_service.dart';

class MealHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate next ID for breakfast/lunch/dinner
  static Future<String> _generateNextId(String collection) async {
    final snapshot = await _firestore
        .collection(collection)
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      // First entry
      switch (collection) {
        case 'breakfast':
          return 'BF001';
        case 'lunch':
          return 'L001';
        case 'dinner':
          return 'D001';
        default:
          throw Exception('Invalid collection name');
      }
    }

    final lastId = snapshot.docs.first.data()['id'] as String;
    final prefix = lastId.substring(0, lastId.length - 3);
    final number = int.parse(lastId.substring(lastId.length - 3));
    final nextNumber = number + 1;
    return '$prefix${nextNumber.toString().padLeft(3, '0')}';
  }

  // Add meal to history
  static Future<String?> addToHistory(String mealId, String collection) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get meal data with custom data if available
      final mealData = await MealService.getMeal(mealId);
      if (mealData == null) return null;

      // Generate next ID
      final nextId = await _generateNextId(collection);

      // Prepare history data
      final historyData = {
        'id': nextId,
        'mealId': mealId,
        'name': mealData['title'] ?? mealData['strMeal'] ?? 'Unknown Meal',
        'calories': mealData['calories'] ?? 0,
        'carbs': mealData['carbs'] ?? 0,
        'protein': mealData['protein'] ?? 0,
        'photo': mealData['imageUrl'] ?? mealData['strMealThumb'] ?? '',
        'user': user.uid,
        'date': FieldValue.serverTimestamp(),
      };

      // Add to collection
      await _firestore.collection(collection).doc(nextId).set(historyData);

      return nextId;
    } catch (e) {
      print('Error adding meal to history: $e');
      return null;
    }
  }

  // Get meal history
  static Future<List<Map<String, dynamic>>> getHistory(
    String collection, {
    String? filter,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      Query query = _firestore
          .collection(collection)
          .where('user', isEqualTo: user.uid);

      // Apply date filter if specified
      if (filter != null) {
        final now = DateTime.now();
        DateTime startDate;

        switch (filter) {
          case 'Today':
            startDate = DateTime(now.year, now.month, now.day);
            break;
          case 'This Month':
            startDate = DateTime(now.year, now.month, 1);
            break;
          case 'This Year':
            startDate = DateTime(now.year, 1, 1);
            break;
          default:
            final snapshot = await query.get();
            return snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
        }

        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting meal history: $e');
      return [];
    }
  }

  // Remove meal from history
  static Future<bool> removeFromHistory(String collection, String historyId) async {
    try {
      await _firestore.collection(collection).doc(historyId).delete();
      return true;
    } catch (e) {
      print('Error removing meal from history: $e');
      return false;
    }
  }
} 