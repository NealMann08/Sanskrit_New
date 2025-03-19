import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'writing_analysis.dart';
import 'translation.dart';
import 'img_gen.dart';
import 'fill_in_the_blank.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sanskrit Learning App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      initialRoute: '/login', // Start with the login screen
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => HomeScreen(title: 'Sanskrit Learning App'),
        '/writing-analysis': (context) => WritingAnalysisScreen(),
        '/translation': (context) => TranslationScreen(),
        '/img-gen': (context) => ImageGenerationScreen(),
        '/fill-in-the-blank': (context) => const FillInTheBlankScreen(),
      },
    );
  }
}