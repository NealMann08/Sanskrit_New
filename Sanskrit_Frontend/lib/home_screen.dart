import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });
  }

  void navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: ${e.toString()}')));
    }
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
              accountName: Text(_user?.displayName ?? 'User'),
              accountEmail: Text(_user?.email ?? 'No email'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child:
                    _user?.photoURL != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(_user!.photoURL!),
                        )
                        : Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.deepPurple,
                        ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Writing Analysis"),
              onTap: () => _navigate(WritingAnalysisScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text("Translation"),
              onTap: () => _navigate(TranslationScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Image Generation"),
              onTap: () => _navigate(ImageGenerationScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text("Fill-in-the-Blank"),
              onTap: () => _navigate(FillInTheBlankScreen()),
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
            Text(
              _user != null
                  ? 'Welcome, ${_user!.displayName ?? _user!.email}!'
                  : 'Welcome to Sanskrit Learning!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _navigate(WritingAnalysisScreen()),
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start Learning"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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

  void _navigate(Widget screen) {
    Navigator.pop(context);
    navigateToScreen(screen);
  }
}
