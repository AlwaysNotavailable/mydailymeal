import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  Map<String, dynamic>? userData;
  double startWeight = 0;
  double currentWeight = 0;
  double height = 0;
  double goalWeight = 0;
  int daysPast = 0;
  List<FlSpot> weightTrend = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) return;

      final progressSnapshot = await FirebaseFirestore.instance
          .collection('progress')
          .where('user', isEqualTo: uid)
          .orderBy('date')
          .get();

      if (progressSnapshot.docs.isEmpty) {
        setState(() {
          userData = userDoc.data();
        });
        return;
      }

      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      QueryDocumentSnapshot<Map<String, dynamic>>? todayDoc;

      for (var doc in progressSnapshot.docs) {
        final ts = doc['date'] as Timestamp;
        final docDate = ts.toDate();
        final docDateOnly = DateTime(docDate.year, docDate.month, docDate.day);
        if (docDateOnly == todayOnly) {
          todayDoc = doc;
          break;
        }
      }

      todayDoc ??= progressSnapshot.docs.last;

      final earliest = progressSnapshot.docs.first;
      final latest = progressSnapshot.docs.last;

      final earliestDate = (earliest['date'] as Timestamp).toDate();
      final latestDate = (latest['date'] as Timestamp).toDate();

      final List<FlSpot> trendPoints = [];
      for (int i = 0; i < progressSnapshot.docs.length; i++) {
        final doc = progressSnapshot.docs[i];
        final weight = (doc['weight'] as num).toDouble();
        trendPoints.add(FlSpot(i.toDouble(), weight));
      }

      setState(() {
        userData = userDoc.data();
        startWeight = (earliest['weight'] as num).toDouble();
        currentWeight = (todayDoc!['weight'] as num).toDouble();
        height = (todayDoc!['height'] as num).toDouble();
        goalWeight = (todayDoc!['goalWeight'] as num).toDouble();
        daysPast = latestDate.difference(earliestDate).inDays;
        weightTrend = trendPoints;
      });
    } catch (e) {
      print("Error fetching progress: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double heightMeters = height / 100;
    final double bmi = currentWeight / (heightMeters * heightMeters);
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
      appBar: AppBar(title: const Text("Progress")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text("Weight Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightTrend,
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            Text("Past $daysPast days", textAlign: TextAlign.center),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Starting Weight", "${startWeight.toStringAsFixed(1)} lbs"),
                _buildStatCard("Current Weight", "${currentWeight.toStringAsFixed(1)} lbs"),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Goal Weight", "${goalWeight.toStringAsFixed(1)} lbs"),
                _buildStatCard("BMI", "${bmi.toStringAsFixed(1)}\n$bmiCategory"),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              calorieChange < 0 ? "Calories to Burn" : "Calories to Reach Goal",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              "${calorieChange.abs().toStringAsFixed(0)} calories",
              textAlign: TextAlign.center,
            ),
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
