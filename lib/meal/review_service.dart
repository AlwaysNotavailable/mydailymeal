import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String?> addReview(String mealId, {
    required int rating,
    required String comment,
    required bool isAnonymous,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final reviewRef = _firestore.collection('Meal').doc(mealId).collection('Review').doc();
      final userName = isAnonymous ? 'Anonymous User' : _formatUserName(user.displayName ?? user.email ?? 'Unknown User');

      await reviewRef.set({
        'id': reviewRef.id,
        'userId': user.uid,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'date': FieldValue.serverTimestamp(),
        'isAnonymous': isAnonymous,
      });

      return reviewRef.id;
    } catch (e) {
      print('Error adding review: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getReviews(String mealId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('Meal')
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
          .collection('Meal')
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

  static Future<bool> updateReview(String mealId, String reviewId, {
    required int rating,
    required String comment,
    required bool isAnonymous,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final reviewRef = _firestore.collection('Meal').doc(mealId).collection('Review').doc(reviewId);
      final reviewDoc = await reviewRef.get();

      if (!reviewDoc.exists || reviewDoc.data()?['userId'] != user.uid) {
        return false;
      }

      final userName = isAnonymous ? 'Anonymous User' : _formatUserName(user.displayName ?? user.email ?? 'Unknown User');

      await reviewRef.update({
        'rating': rating,
        'comment': comment,
        'date': FieldValue.serverTimestamp(),
        'userName': userName,
        'isAnonymous': isAnonymous,
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

      final reviewRef = _firestore.collection('Meal').doc(mealId).collection('Review').doc(reviewId);
      final reviewDoc = await reviewRef.get();

      if (!reviewDoc.exists || reviewDoc.data()?['userId'] != user.uid) {
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