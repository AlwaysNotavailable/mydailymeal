import 'package:flutter/material.dart';
import 'progress.dart'; // Make sure this is imported

class IdealWeight extends StatefulWidget {
  @override
  _IdealWeightState createState() => _IdealWeightState();
}

class _IdealWeightState extends State<IdealWeight> {
  final TextEditingController _currentWeightController = TextEditingController();
  final TextEditingController _goalWeightController = TextEditingController();

  void _saveWeights() {
    final String current = _currentWeightController.text;
    final String goal = _goalWeightController.text;



    if (current.isNotEmpty && goal.isNotEmpty) {
      final double currentDouble = double.tryParse(current) ?? 0.0;
      final double goalDouble = double.tryParse(goal) ?? 0.0;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgressPage(
            currentWeight: currentDouble,
            goalWeight: goalDouble,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _currentWeightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ideal Weight'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("What's your goal?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("You can set a weight goal to help you track your progress."),
            SizedBox(height: 16),
            TextField(
              controller: _currentWeightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Current',
                suffixText: 'lb',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _goalWeightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Goal',
                suffixText: 'lb',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveWeights,
              child: Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
