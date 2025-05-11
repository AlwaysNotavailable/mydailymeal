import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String?> addReview(
    String mealId, {
    required int rating,
    required String comment,
    bool isAnonymous = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      String finalMealId = mealId;
      
      // If mealId is null or not starting with M, save it to Meals collection first
      if (mealId == null || !mealId.toString().startsWith('M')) {
        // Get the latest meal ID
        final mealsSnapshot = await _firestore
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

        // Save the meal to Meals collection
        await _firestore.collection('Meals').doc(newId).set({
          'id': newId,
          'title': mealId?.toString() ?? 'Unknown Meal',
          'calories': 0,
          'protein': 0,
          'carbs': 0,
          'imageUrl': '',
          'userId': user.uid,
          'isCustom': false,
          'type': 'api',
          'originalId': mealId?.toString() ?? '',
        });

        finalMealId = newId;
      }

      final reviewRef = _firestore.collection('Meals').doc(finalMealId).collection('Review').doc();
      final userName = isAnonymous ? 'Anonymous User' : _formatUserName(user.displayName ?? user.email ?? 'Unknown User');

      final reviewData = {
        'id': reviewRef.id,
        'userId': user.uid,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'isAnonymous': isAnonymous,
        'date': FieldValue.serverTimestamp(),
      };

      await reviewRef.set(reviewData);
      return reviewRef.id;
    } catch (e) {
      print('Error adding review: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getReviews(String mealId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('Meals')
          .doc(mealId)
          .collection('Review')
          .orderBy('date', descending: true)
          .get();

      return reviewsSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserReview(String mealId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final reviewSnapshot = await _firestore
          .collection('Meals')
          .doc(mealId)
          .collection('Review')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (reviewSnapshot.docs.isEmpty) return null;
      return reviewSnapshot.docs.first.data();
    } catch (e) {
      print('Error getting user review: $e');
      return null;
    }
  }

  static Future<bool> updateReview(
    String mealId,
    String reviewId, {
    required int rating,
    required String comment,
    bool isAnonymous = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final reviewRef = _firestore.collection('Meals').doc(mealId).collection('Review').doc(reviewId);
      final reviewDoc = await reviewRef.get();

      if (!reviewDoc.exists || reviewDoc.data()?['userId'] != user.uid) {
        return false;
      }

      final userName = isAnonymous ? 'Anonymous User' : _formatUserName(user.displayName ?? user.email ?? 'Unknown User');

      await reviewRef.update({
        'rating': rating,
        'comment': comment,
        'isAnonymous': isAnonymous,
        'userName': userName,
        'date': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  static Future<bool> deleteReview(String mealId, String reviewId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final reviewRef = _firestore.collection('Meals').doc(mealId).collection('Review').doc(reviewId);
      final reviewDoc = await reviewRef.get();

      if (!reviewDoc.exists) return false;

      // Check if user is admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final isAdmin = userDoc.data()?['isAdmin'] ?? false;

      // Allow deletion if user is admin or owns the review
      if (!isAdmin && reviewDoc.data()?['userId'] != user.uid) {
        return false;
      }

      await reviewRef.delete();
      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  static String _formatUserName(String fullName) {
    if (fullName.isEmpty) return 'Unknown User';
    
    final parts = fullName.split(' ');
    if (parts.length == 1) {
      return '${parts[0][0]}***';
    }
    
    final firstName = parts[0];
    final lastName = parts[parts.length - 1];
    return '${firstName[0]}*** ${lastName[0]}***';
  }
} 