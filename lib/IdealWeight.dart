import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'progress.dart';
import 'package:intl/intl.dart';

class IdealWeight extends StatefulWidget {
  @override
  _IdealWeightState createState() => _IdealWeightState();
}

class _IdealWeightState extends State<IdealWeight> {
  final TextEditingController _currentWeightController = TextEditingController();
  final TextEditingController _goalWeightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfDataExistsForToday();
  }

  Future<void> _checkIfDataExistsForToday() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('progress')
          .where('user', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProgressPage()),
          );
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error checking progress for today: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<String> _generateProgressId() async {
    final snapshot = await FirebaseFirestore.instance.collection('progress').get();
    int count = snapshot.docs.length + 1;
    return 'P${count.toString().padLeft(4, '0')}';
  }

  Future<void> _saveWeights() async {
    final current = _currentWeightController.text;
    final goal = _goalWeightController.text;
    final height = _heightController.text;

    if (current.isNotEmpty && goal.isNotEmpty && height.isNotEmpty) {
      final double currentDouble = double.tryParse(current) ?? 0.0;
      final double goalDouble = double.tryParse(goal) ?? 0.0;
      final double heightDouble = double.tryParse(height) ?? 0.0;
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final DateTime now = DateTime.now();
      final DateTime dateOnly = DateTime(now.year, now.month, now.day);
      final Timestamp timestampDate = Timestamp.fromDate(dateOnly);

      final progressId = await _generateProgressId();

      await FirebaseFirestore.instance.collection('progress').doc(progressId).set({
        'weight': currentDouble,
        'goalWeight': goalDouble,
        'height': heightDouble,
        'date': timestampDate,
        'user': user.uid,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProgressPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _currentWeightController.dispose();
    _goalWeightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ideal Weight')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("What's your goal?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Set your weight goal to track your progress."),
            const SizedBox(height: 16),
            TextField(
              controller: _currentWeightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current Weight',
                suffixText: 'lb',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current Height',
                suffixText: 'in',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _goalWeightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Goal Weight',
                suffixText: 'lb',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveWeights,
              child: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
