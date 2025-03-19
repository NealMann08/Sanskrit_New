import 'package:flutter/material.dart';
import '../api_service.dart';

class WritingAnalysisScreen extends StatefulWidget {
  const WritingAnalysisScreen({super.key});

  @override
  _WritingAnalysisScreenState createState() => _WritingAnalysisScreenState();
}

class _WritingAnalysisScreenState extends State<WritingAnalysisScreen> {
  String feedback = "";
  TextEditingController textController = TextEditingController();

  Future<void> analyzeWriting() async {
    if (textController.text.isEmpty) return;

    try {
      final data = await ApiService.fetchWritingAnalysis(textController.text);
      setState(() {
        feedback = data['feedback'];
      });
    } catch (e) {
      print("Error fetching feedback: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Writing Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: textController,
              decoration: InputDecoration(labelText: 'Enter your Sanskrit text'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: analyzeWriting,
              child: Text('Analyze'),
            ),
            SizedBox(height: 20),
            Text(feedback, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
