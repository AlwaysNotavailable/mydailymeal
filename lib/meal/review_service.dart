import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> addReview(String mealId, int rating, String comment, {bool isAnonymous = false}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final reviewRef = _firestore.collection('Meal').doc(mealId).collection('Review').doc();
    final userName = isAnonymous ? 'Anonymous User' : _formatUserName(user.displayName ?? user.email ?? 'Unknown User');

    await reviewRef.set({
      'userId': user.uid,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'date': FieldValue.serverTimestamp(),
      'isAnonymous': isAnonymous,
    });
  }

  static Future<List<Map<String, dynamic>>> getReviews(String mealId) async {
    final reviewsSnapshot = await _firestore
        .collection('Meal')
        .doc(mealId)
        .collection('Review')
        .orderBy('date', descending: true)
        .get();

    return reviewsSnapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<Map<String, dynamic>?> getUserReview(String mealId) async {
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
  }

  static Future<void> updateReview(String mealId, int rating, String comment, {bool isAnonymous = false}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final reviewSnapshot = await _firestore
        .collection('Meal')
        .doc(mealId)
        .collection('Review')
        .where('userId', isEqualTo: user.uid)
        .get();

    if (reviewSnapshot.docs.isEmpty) {
      throw Exception('Review not found');
    }

    final reviewRef = reviewSnapshot.docs.first.reference;
    final userName = isAnonymous ? 'Anonymous User' : _formatUserName(user.displayName ?? user.email ?? 'Unknown User');

    await reviewRef.update({
      'rating': rating,
      'comment': comment,
      'date': FieldValue.serverTimestamp(),
      'userName': userName,
      'isAnonymous': isAnonymous,
    });
  }

  static Future<void> deleteReview(String mealId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final reviewSnapshot = await _firestore
        .collection('Meal')
        .doc(mealId)
        .collection('Review')
        .where('userId', isEqualTo: user.uid)
        .get();

    if (reviewSnapshot.docs.isEmpty) {
      throw Exception('Review not found');
    }

    await reviewSnapshot.docs.first.reference.delete();
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