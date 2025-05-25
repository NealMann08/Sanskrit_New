import 'package:flutter/material.dart';
import '../api_service.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  _TranslationScreenState createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  String exercise = "";
  List<String> correctAnswers = [];
  String userAnswer = "";
  String feedback = "";
  bool isLoading = true;
  bool _hasInitialData = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialExercise();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
      _textController.clear();
    });

    try {
      final data = await ApiService.fetchTranslationExercise();
      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }

      setState(() {
        exercise = data['exercise'] ?? '';
        correctAnswers = List<String>.from(data['correct_answers'] ?? []);
      });
    } catch (e) {
      setState(() => feedback = "Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void checkAnswer() {
    // Safely handle null or empty values
    if (userAnswer.isEmpty) {
      setState(() {
        feedback = "❌ Please enter a translation";
      });
      return;
    }

    final cleanedAnswer = userAnswer.trim().toLowerCase();
    setState(() {
      if (correctAnswers.contains(cleanedAnswer)) {
        feedback = "✅ Perfect! Well done!";
      } else {
        // Format multiple correct answers nicely
        final formattedAnswers = correctAnswers.join(' or ');
        feedback = "❌ Incorrect. Acceptable answers: $formattedAnswers";
      }
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
            if (isLoading && !_hasInitialData)
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
                ? const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Loading next question...'),
                    ],
                  ),
                )
                : Column(
                  children: [
                    Text(exercise, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _textController,
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
