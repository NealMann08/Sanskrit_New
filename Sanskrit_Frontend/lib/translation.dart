import 'package:flutter/material.dart';
import '../api_service.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  _TranslationScreenState createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  String exercise = "";
  String correctAnswer = "";
  TextEditingController userResponseController = TextEditingController();
  String feedback = "";

  @override
  void initState() {
    super.initState();
    fetchExercise();
  }

  Future<void> fetchExercise() async {
    try {
      final data = await ApiService.fetchTranslationExercise();
      print("API Response: $data");
      setState(() {
        exercise = data['exercise'];
        correctAnswer = data['correct_answer'];
        feedback = "";
      });
    } catch (e) {
      print("Error fetching translation exercise: $e");
    }
  }

  void checkAnswer() {
    if (userResponseController.text.trim().toLowerCase() == correctAnswer.toLowerCase()) {
      setState(() {
        feedback = "✅ Correct!";
      });
    } else {
      setState(() {
        feedback = "❌ Incorrect. The correct answer is: $correctAnswer";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Translation Exercise')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Translate this Sanskrit word:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text(exercise, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: userResponseController,
              decoration: InputDecoration(labelText: 'Enter your answer'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: checkAnswer,
              child: Text('Submit'),
            ),
            SizedBox(height: 20),
            Text(feedback, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchExercise,
              child: Text('Next Question'),
            ),
          ],
        ),
      ),
    );
  }
}
