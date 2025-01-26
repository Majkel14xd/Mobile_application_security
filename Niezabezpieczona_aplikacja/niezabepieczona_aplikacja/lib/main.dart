import 'package:flutter/material.dart';
import 'package:mobile_application_security_Project/read_notes.dart';
import 'package:mobile_application_security_Project/save_notes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // kazde uruchomienie musi miec nowy token
  await generateNewToken();
  runApp(const MyApp());
}

// generowanie tokenu i zapis w SharedPreferences
Future<void> generateNewToken() async {
  final prefs = await SharedPreferences.getInstance();
  final newToken = Uuid().v4(); // generowanie tokenu
  await prefs.setString('token', newToken); // zapis
  print('New token generated: $newToken');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Notes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReadNotes()),
                );
              },
              child: const Text('Read Notes'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SaveNotes()),
                );
              },
              child: const Text('Save Notes'),
            ),
          ],
        ),
      ),
    );
  }
}
