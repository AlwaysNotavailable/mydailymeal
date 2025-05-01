import 'package:flutter/material.dart';

class IdealWeight extends StatefulWidget {
  const IdealWeight({super.key});

  @override
  State<IdealWeight> createState() => _IdealWeightState();
}

class _IdealWeightState extends State<IdealWeight> {
  final TextEditingController _currentWeightController = TextEditingController(text: '110lb');
  final TextEditingController _goalWeightController = TextEditingController(text: '100lb');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ideal Weight'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's your goal?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can set a weight goal to help you track your progress.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 32),
            const Text('Current'),
            const SizedBox(height: 8),
            _buildWeightField(_currentWeightController),
            const SizedBox(height: 24),
            const Text('Goal'),
            const SizedBox(height: 8),
            _buildWeightField(_goalWeightController),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // Handle save action here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Weight goal saved!')),
                  );
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWeightField(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
