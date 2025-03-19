import 'package:flutter/material.dart';
import '../api_service.dart';

class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  _ImageGenerationScreenState createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen> {
  String imageUrl = "";
  TextEditingController promptController = TextEditingController();

  Future<void> generateImage() async {
    if (promptController.text.isEmpty) return;

    try {
      final data = await ApiService.fetchImageGeneration(promptController.text);
      setState(() {
        imageUrl = data['image_url'];
      });
    } catch (e) {
      print("Error generating image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final proxyUrl = imageUrl.isNotEmpty
        ? "http://127.0.0.1:5000/proxy-image?url=${Uri.encodeComponent(imageUrl)}"
        : "";

    return Scaffold(
      appBar: AppBar(title: Text('Image Generation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: promptController,
              decoration: InputDecoration(labelText: 'Enter a word or concept'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: generateImage,
              child: Text('Generate Image'),
            ),
            SizedBox(height: 20),
            imageUrl.isNotEmpty
                ? Image.network(
                    proxyUrl,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 50),
                          Text('Failed to load image.'),
                        ],
                      );
                    },
                  )
                : Text('No image generated yet.'),
          ],
        ),
      ),
    );
  }
}
