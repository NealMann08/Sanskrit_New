import 'package:flutter/material.dart';
import '../api_service.dart';

class FillInTheBlankScreen extends StatefulWidget {
  const FillInTheBlankScreen({super.key});

  @override
  _FillInTheBlankScreenState createState() => _FillInTheBlankScreenState();
}

class _FillInTheBlankScreenState extends State<FillInTheBlankScreen> {
  String exercise = "";
  List<String> choices = [];
  int correctAnswerIndex = -1; // Store the index of the correct answer
  String feedback = "";

  @override
  void initState() {
    super.initState();
    fetchExercise();
  }

  Future<void> fetchExercise() async {
    try {
      final data = await ApiService.fetchFillInTheBlank();
      setState(() {
        exercise = data['exercise'];
        choices = List<String>.from(data['choices']);
        correctAnswerIndex = int.parse(data['correct_answer']); // Convert string to int
        feedback = ""; // Reset feedback when fetching a new question
      });
    } catch (e) {
      print("Error fetching exercise: $e");
    }
  }

  void checkAnswer(int selectedIndex) {
    setState(() {
      feedback = (selectedIndex == correctAnswerIndex)
          ? "✅ Correct!"
          : "❌ Incorrect. The correct answer is: ${choices[correctAnswerIndex]}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fill-in-the-Blank Exercise')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exercise:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(exercise, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Column(
              children: choices.asMap().entries.map((entry) {
                int idx = entry.key;
                String choice = entry.value;
                return ElevatedButton(
                  onPressed: () => checkAnswer(idx),
                  child: Text(choice),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(feedback, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchExercise,
              child: const Text('Next Question'),
            ),
          ],
        ),
      ),
    );
  }
}