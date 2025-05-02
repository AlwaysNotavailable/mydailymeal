import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProgressPage extends StatefulWidget {
  final double currentWeight;
  final double goalWeight;

  const ProgressPage({super.key, required this.currentWeight, required this.goalWeight});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  Map<String, dynamic>? userData;
  int daysPast = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    calculateDaysPast();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        userData = doc.data();
      });
    }
  }

  Future<void> calculateDaysPast() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    List<DateTime> allDates = [];

    for (final meal in ['breakfast', 'lunch', 'dinner']) {
      final snapshot = await FirebaseFirestore.instance
          .collection(meal)
          .where('uid', isEqualTo: uid)
          .get();

      for (var doc in snapshot.docs) {
        Timestamp ts = doc['date'];
        allDates.add(ts.toDate());
      }
    }

    if (allDates.isNotEmpty) {
      allDates.sort();
      setState(() {
        daysPast = allDates.last.difference(allDates.first).inDays;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double startWeight = (userData!['weight'] ?? 0).toDouble();
    final double heightInMeters = (userData!['height'] ?? 0) / 100;
    final double currentWeight = widget.currentWeight;
    final double goalWeight = widget.goalWeight;

    final double bmi = currentWeight / (heightInMeters * heightInMeters);
    final double weightDiff = currentWeight - goalWeight;
    final double caloriesPerPound = 3500;
    final double calorieChange = weightDiff * caloriesPerPound;

    String bmiCategory = '';
    if (bmi < 18.5) {
      bmiCategory = "Underweight";
    } else if (bmi < 25) {
      bmiCategory = "Normal";
    } else if (bmi < 30) {
      bmiCategory = "Overweight";
    } else {
      bmiCategory = "Obese";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Progress"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Weight Trend
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Weight", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "${(currentWeight - startWeight).toStringAsFixed(1)} lbs",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Past $daysPast days ${weightDiff >= 0 ? "-${weightDiff.toStringAsFixed(1)} lbs" : "+${(-weightDiff).toStringAsFixed(1)} lbs"}",
                      style: TextStyle(color: weightDiff <= 0 ? Colors.green : Colors.red),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stats Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Starting Weight", "${startWeight.toStringAsFixed(1)}lbs"),
                _buildStatCard("Current Weight", "${currentWeight.toStringAsFixed(1)}lbs"),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Goal Weight", "${goalWeight.toStringAsFixed(1)}lbs"),
                _buildStatCard("BMI", "${bmi.toStringAsFixed(1)}\n$bmiCategory"),
              ],
            ),
            const SizedBox(height: 20),

            // Calories
            Text(
              calorieChange < 0 ? "Calories to Burn" : "Calories to Reach Goal",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text("${calorieChange.abs().toStringAsFixed(0)} calories"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
