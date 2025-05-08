import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Format user name to show only first word and first letter of second word
  static String _formatUserName(String name) {
    final words = name.split(' ');
    if (words.length == 1) return words[0];
    return '${words[0]} ${words[1][0]}***';
  }

  // Generate next review ID
  static Future<String> _generateNextReviewId(String mealId) async {
    final snapshot = await _firestore
        .collection('Meals')
        .doc(mealId)
        .collection('Review')
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'R001';
    }

    final lastId = snapshot.docs.first.data()['id'] as String;
    final number = int.parse(lastId.substring(1));
    final nextNumber = number + 1;
    return 'R${nextNumber.toString().padLeft(3, '0')}';
  }

  // Add a review
  static Future<String?> addReview(String mealId, {
    required int rating,
    required String comment,
    required bool isAnonymous,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final reviewId = await _generateNextReviewId(mealId);
      
      final reviewData = {
        'id': reviewId,
        'userId': user.uid,
        'userName': isAnonymous ? 'Anonymous' : _formatUserName(user.displayName ?? 'Anonymous'),
        'isAnonymous': isAnonymous,
        'rating': rating,
        'comment': comment,
        'date': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('Meals')
          .doc(mealId)
          .collection('Review')
          .doc(reviewId)
          .set(reviewData);

      return reviewId;
    } catch (e) {
      print('Error adding review: $e');
      return null;
    }
  }

  // Get all reviews for a meal
  static Future<List<Map<String, dynamic>>> getReviews(String mealId) async {
    try {
      final snapshot = await _firestore
          .collection('Meals')
          .doc(mealId)
          .collection('Review')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  // Update a review
  static Future<bool> updateReview(
    String mealId,
    String reviewId, {
    required int rating,
    required String comment,
    required bool isAnonymous,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if the review belongs to the current user
      final reviewDoc = await _firestore
          .collection('Meals')
          .doc(mealId)
          .collection('Review')
          .doc(reviewId)
          .get();

      if (!reviewDoc.exists || reviewDoc.data()?['userId'] != user.uid) {
        return false;
      }

      await _firestore
          .collection('Meals')
          .doc(mealId)
          .collection('Review')
          .doc(reviewId)
          .update({
        'rating': rating,
        'comment': comment,
        'isAnonymous': isAnonymous,
        'userName': isAnonymous ? 'Anonymous' : _formatUserName(user.displayName ?? 'Anonymous'),
        'date': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  // Delete a review
  static Future<bool> deleteReview(String mealId, String reviewId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if the review belongs to the current user
      final reviewDoc = await _firestore
          .collection('Meals')
          .doc(mealId)
          .collection('Review')
          .doc(reviewId)
          .get();

      if (!reviewDoc.exists || reviewDoc.data()?['userId'] != user.uid) {
        return false;
      }

      await _firestore
          .collection('Meals')
          .doc(mealId)
          .collection('Review')
          .doc(reviewId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }
} 