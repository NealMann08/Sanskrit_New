import 'package:flutter/material.dart';
import '../api_service.dart';

class FillInTheBlankScreen extends StatefulWidget {
  const FillInTheBlankScreen({super.key});

  @override
  _FillInTheBlankScreenState createState() => _FillInTheBlankScreenState();
}

class _FillInTheBlankScreenState extends State<FillInTheBlankScreen> {
  String exercise = "Loading exercise...";
  List<String> choices = [];
  int? correctAnswerIndex;
  String feedback = "";
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchExercise();
  }

  Future<void> fetchExercise() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.fetchFillInTheBlank();

      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      final answer = data['correct_answer']?.toString() ?? '1';
      final parsedAnswer = int.tryParse(answer) ?? 1;

      setState(() {
        exercise = data['exercise'] ?? "Could not load exercise";
        choices = List<String>.from(data['choices'] ?? []);
        correctAnswerIndex = parsedAnswer - 1; // Convert to 0-based index
        feedback = "";
      });
    } catch (e) {
      setState(() {
        errorMessage =
            "Failed to load exercise: ${e.toString().replaceAll('Exception: ', '')}";
        exercise = "Error loading exercise";
        choices = [];
        correctAnswerIndex = null;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void checkAnswer(int selectedIndex) {
    if (correctAnswerIndex == null || choices.isEmpty) return;

    setState(() {
      final correctAnswer =
          choices.length > correctAnswerIndex!
              ? choices[correctAnswerIndex!]
              : 'Unknown answer';

      feedback =
          (selectedIndex == correctAnswerIndex)
              ? "✅ Correct!"
              : "❌ Incorrect. The correct answer is: $correctAnswer";
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
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),

            const Text(
              'Exercise:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(exercise, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (choices.isEmpty)
              const Text(
                'No answer choices available',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                children:
                    choices.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final choice = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          onPressed: () => checkAnswer(idx),
                          child: Text(choice),
                        ),
                      );
                    }).toList(),
              ),

            const SizedBox(height: 20),
            if (feedback.isNotEmpty)
              Text(
                feedback,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: feedback.contains('✅') ? Colors.green : Colors.red,
                ),
              ),

            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Next Question'),
                onPressed: isLoading ? null : fetchExercise,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
