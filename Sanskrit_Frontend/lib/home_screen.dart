import 'package:flutter/material.dart';
import 'api_service.dart';
import 'writing_analysis.dart';
import 'translation.dart';
import 'img_gen.dart';
import 'fill_in_the_blank.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }
  
  Future<void> _loadUser() async {
    final user = await ApiService.getLoggedInUser();
    setState(() {
      username = user;
    });
  }

  void navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  void _logout() async {
    await ApiService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(username ?? 'User'),
              accountEmail: Text(username != null ? '$username@example.com' : 'user@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.deepPurple),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Writing Analysis"),
              onTap: () {
                Navigator.pop(context);
                navigateToScreen(WritingAnalysisScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text("Translation"),
              onTap: () {
                Navigator.pop(context);
                navigateToScreen(TranslationScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Image Generation"),
              onTap: () {
                Navigator.pop(context);
                navigateToScreen(ImageGenerationScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text("Fill-in-the-Blank"),
              onTap: () {
                Navigator.pop(context);
                navigateToScreen(FillInTheBlankScreen());
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to Sanskrit Learning!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => navigateToScreen(WritingAnalysisScreen()),
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start Learning"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}