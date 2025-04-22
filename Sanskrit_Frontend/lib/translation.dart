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
  String userAnswer = "";
  String feedback = "";
  bool isLoading = true; // Start in loading state
  bool _hasInitialData = false;

  @override
  void initState() {
    super.initState();
    _loadInitialExercise();
  }

  Future<void> _loadInitialExercise() async {
    if (!_hasInitialData) {
      await fetchExercise();
      _hasInitialData = true;
    }
  }

  Future<void> fetchExercise() async {
    setState(() {
      isLoading = true;
      feedback = "";
      userAnswer = "";
    });

    try {
      final data = await ApiService.fetchTranslationExercise();
      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }

      setState(() {
        exercise = data['exercise'];
        correctAnswer = data['correct_answer'].toLowerCase().trim();
      });
    } catch (e) {
      setState(() => feedback = "Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void checkAnswer() {
    final cleanedAnswer = userAnswer.toLowerCase().trim();
    setState(() {
      feedback =
          cleanedAnswer == correctAnswer
              ? "✅ Perfect! Well done!"
              : "❌ Incorrect. Correct answer: $correctAnswer";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Translation Exercise')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('Loading first exercise...'),
                    ],
                  ),
                ),
              )
            else
              const Text(
                'Translate this Sanskrit Text to English:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    Text(exercise, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: TextEditingController(text: userAnswer),
                      decoration: const InputDecoration(
                        labelText: 'Your English translation',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => userAnswer = value,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: checkAnswer,
                          child: const Text('Submit Answer'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: fetchExercise,
                          child: const Text('Next Question'),
                        ),
                      ],
                    ),
                    if (feedback.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          feedback,
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                feedback.contains('✅')
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
