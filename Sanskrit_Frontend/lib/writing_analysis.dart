import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class WritingAnalysisScreen extends StatefulWidget {
  const WritingAnalysisScreen({super.key});

  @override
  _WritingAnalysisScreenState createState() => _WritingAnalysisScreenState();
}

class _WritingAnalysisScreenState extends State<WritingAnalysisScreen> {
  File? _image;
  final TextEditingController _textController = TextEditingController();
  String feedback = "";
  bool isLoading = false;
  bool _useImageInput = false; // Toggle between text/image
  final bool _currentUseImageInput = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _textController.clear(); // Clear text when image is selected
      });
    }
  }

  void _handleInputTypeChange(bool newValue) async {
    if (feedback.isNotEmpty) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Clear Results?'),
              content: const Text(
                'Switching input types will clear current analysis. Continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Clear'),
                ),
              ],
            ),
      );

      if (shouldProceed != true) {
        return; // User canceled
      }
    }

    setState(() {
      _useImageInput = newValue;
      _image = newValue ? null : _image; // Clear image when switching to text
      _textController.clear();
      feedback = "";
    });
  }

  Future<void> _analyze() async {
    setState(() {
      isLoading = true;
      feedback = "";
    });

    try {
      if (_useImageInput && _image != null) {
        // Image analysis
        final bytes = await _image!.readAsBytes();
        final base64Image = base64Encode(bytes);
        final data = await ApiService.analyzeSanskritImage(base64Image);
        feedback = data['analysis'] ?? "No analysis received";
      } else if (!_useImageInput && _textController.text.isNotEmpty) {
        // Text analysis
        final data = await ApiService.analyzeSanskritText(_textController.text);
        feedback = data['analysis'] ?? "No analysis received";
      } else {
        throw "Please provide either text or image";
      }
    } catch (e) {
      feedback = "Error: ${e.toString()}";
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sanskrit Writing Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input Type Toggle
            Row(
              children: [
                const Text("Input Type:"),
                const SizedBox(width: 10),
                Switch(
                  value: _useImageInput,
                  onChanged: (value) => _handleInputTypeChange(value),
                ),
                Text(_useImageInput ? "Image" : "Text"),
              ],
            ),

            const SizedBox(height: 20),

            // Dynamic Input Section
            _useImageInput
                ? Column(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child:
                          _image == null
                              ? Center(
                                child: TextButton(
                                  onPressed: _pickImage,
                                  child: const Text('Tap to upload image'),
                                ),
                              )
                              : Image.file(_image!, fit: BoxFit.contain),
                    ),
                    if (_image != null)
                      TextButton(
                        onPressed: () => setState(() => _image = null),
                        child: const Text('Remove image'),
                      ),
                  ],
                )
                : TextField(
                  controller: _textController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Type your Sanskrit text here',
                    border: OutlineInputBorder(),
                  ),
                ),

            const SizedBox(height: 20),

            // Analyze Button
            ElevatedButton(
              onPressed: isLoading ? null : _analyze,
              child:
                  isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Analyze Writing'),
            ),

            // Results
            if (feedback.isNotEmpty)
              Expanded(
                child: Markdown(
                  data: feedback,
                  styleSheet: MarkdownStyleSheet(
                    h1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    h2: TextStyle(fontSize: 20, color: Colors.blueGrey),
                    p: TextStyle(fontSize: 16, height: 1.4),
                    listBullet: TextStyle(fontSize: 16),
                    strong: TextStyle(fontWeight: FontWeight.bold),
                    em: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  onTapLink: (text, href, title) {
                    // Handle links if needed
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
