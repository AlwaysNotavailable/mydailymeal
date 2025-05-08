import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_meal.dart';
import 'meal_service.dart';
import 'MealHistoryService.dart';
import 'review_service.dart';

class FoodDetail extends StatefulWidget {
  final Map<String, dynamic> meal;
  final String selectedFilter;

  const FoodDetail({
    super.key,
    required this.meal,
    required this.selectedFilter,
  });

  @override
  State<FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<FoodDetail> {
  bool _isLoading = false;
  Map<String, dynamic>? _userCustomData;
  List<Map<String, dynamic>> _reviews = [];
  final _commentController = TextEditingController();
  int _selectedRating = 0;
  Map<String, dynamic>? _userReview;
  bool _isAnonymous = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserCustomData();
    _loadReviews();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCustomData() async {
    try {
      final mealData = await MealService.getMeal(widget.meal['id']);
      if (mealData != null) {
        setState(() {
          _userCustomData = mealData;
        });
      }
    } catch (e) {
      print('Error loading user custom data: $e');
    }
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await ReviewService.getReviews(widget.meal['id']);
      final user = FirebaseAuth.instance.currentUser;
      
      setState(() {
        _reviews = reviews;
        _userReview = user != null 
            ? reviews.where((review) => review['userId'] == user.uid).firstOrNull
            : null;
      });
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }

  Future<void> _editMeal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMeal(
          meal: _userCustomData ?? widget.meal,
        ),
      ),
    );

    if (result == true) {
      _loadUserCustomData();
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_userReview != null) {
        // Update existing review
        final success = await ReviewService.updateReview(
          widget.meal['id'],
          _userReview!['id'],
          rating: _selectedRating,
          comment: _commentController.text,
          isAnonymous: _isAnonymous,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Update the local review data
          setState(() {
            _userReview = {
              ..._userReview!,
              'rating': _selectedRating,
              'comment': _commentController.text,
              'isAnonymous': _isAnonymous,
              'userName': _isAnonymous ? 'Anonymous' : _userReview!['userName'],
              'date': Timestamp.now(),
            };
            _isEditing = false;
          });
        }
      } else {
        // Add new review
        final reviewId = await ReviewService.addReview(
          widget.meal['id'],
          rating: _selectedRating,
          comment: _commentController.text,
          isAnonymous: _isAnonymous,
        );

        if (reviewId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Add the new review to local data
          final user = FirebaseAuth.instance.currentUser;
          setState(() {
            _userReview = {
              'id': reviewId,
              'userId': user?.uid,
              'userName': _isAnonymous ? 'Anonymous' : user?.displayName,
              'rating': _selectedRating,
              'comment': _commentController.text,
              'isAnonymous': _isAnonymous,
              'date': Timestamp.now(),
            };
          });
        }
      }

      _commentController.clear();
      setState(() {
        _selectedRating = 0;
        _isAnonymous = false;
      });
      _loadReviews();
    } catch (e) {
      print('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error submitting review'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReview() async {
    if (_userReview == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await ReviewService.deleteReview(
        widget.meal['id'],
        _userReview!['id'],
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _commentController.clear();
        setState(() {
          _selectedRating = 0;
          _isAnonymous = false;
          _userReview = null;
        });
        _loadReviews();
      }
    } catch (e) {
      print('Error deleting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error deleting review'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _selectedRating = _userReview?['rating'] ?? 0;
      _commentController.text = _userReview?['comment'] ?? '';
      _isAnonymous = _userReview?['isAnonymous'] ?? false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _selectedRating = 0;
      _commentController.clear();
      _isAnonymous = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use user custom data if available, otherwise use original meal data
    final displayData = _userCustomData ?? widget.meal;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(displayData['title'] ?? displayData['strMeal'] ?? 'Meal Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editMeal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayData['imageUrl'] != null || displayData['strMealThumb'] != null)
                    Image.network(
                      displayData['imageUrl'] ?? displayData['strMealThumb'],
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayData['title'] ?? displayData['strMeal'] ?? 'Unknown Meal',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildNutritionInfo('Calories', '${displayData['calories'] ?? 'N/A'} cal'),
                        _buildNutritionInfo('Carbs', '${displayData['carbs'] ?? 'N/A'}g'),
                        _buildNutritionInfo('Protein', '${displayData['protein'] ?? 'N/A'}g'),
                        if (displayData['fat'] != null)
                          _buildNutritionInfo('Fat', '${displayData['fat']}g'),
                        const SizedBox(height: 24),
                        if (displayData['strInstructions'] != null) ...[
                          const Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(displayData['strInstructions']),
                        ],
                        const SizedBox(height: 24),
                        const Text(
                          'Add to Meal',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _addToMeal('breakfast'),
                                icon: const Icon(Icons.wb_sunny_outlined),
                                label: const Text('Breakfast'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[100],
                                  foregroundColor: Colors.orange[900],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _addToMeal('lunch'),
                                icon: const Icon(Icons.restaurant),
                                label: const Text('Lunch'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[100],
                                  foregroundColor: Colors.green[900],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _addToMeal('dinner'),
                                icon: const Icon(Icons.nightlight_round),
                                label: const Text('Dinner'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[100],
                                  foregroundColor: Colors.blue[900],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Reviews',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Review form
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Review',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_userReview != null && !_isEditing) ...[
                                  // Display user's review
                                  Row(
                                    children: [
                                      Text(
                                        _userReview!['userName'] ?? 'Anonymous',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _userReview!['date'] != null
                                            ? (_userReview!['date'] as Timestamp).toDate().toString().split(' ')[0]
                                            : 'Unknown date',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < _userReview!['rating']
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_userReview!['comment'] ?? ''),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: _startEditing,
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: _deleteReview,
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  // Review input form
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (index) {
                                      return IconButton(
                                        icon: Icon(
                                          index < _selectedRating
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 32,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _selectedRating = index + 1;
                                          });
                                        },
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _commentController,
                                    decoration: const InputDecoration(
                                      hintText: 'Write your review...',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _isAnonymous,
                                        onChanged: (value) {
                                          setState(() {
                                            _isAnonymous = value ?? false;
                                          });
                                        },
                                      ),
                                      const Text('Post as Anonymous'),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (_isEditing) ...[
                                        TextButton(
                                          onPressed: _cancelEditing,
                                          child: const Text('Cancel'),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      ElevatedButton(
                                        onPressed: _submitReview,
                                        child: Text(_isEditing ? 'Update Review' : 'Submit Review'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Other reviews list
                        ..._reviews.where((review) => review['userId'] != FirebaseAuth.instance.currentUser?.uid)
                            .map((review) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      review['userName'] ?? 'Anonymous',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      review['date'] != null
                                          ? (review['date'] as Timestamp).toDate().toString().split(' ')[0]
                                          : 'Unknown date',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < review['rating']
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 8),
                                Text(review['comment'] ?? ''),
                              ],
                            ),
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNutritionInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _addToMeal(String collection) async {
    setState(() => _isLoading = true);
    try {
      final result = await MealHistoryService.addToHistory(
        widget.meal['id'],
        collection,
      );

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to $collection successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add to $collection'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding to $collection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to $collection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
} 