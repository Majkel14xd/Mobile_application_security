import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_application_security_Project/read_notes.dart';
import 'package:mobile_application_security_Project/save_notes.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // kazde uruchomienie musi miec nowy token
  await dotenv.load(fileName: ".env");
  await generateNewToken();
  runApp(const MyApp());
}

// instancja secureStorage
final FlutterSecureStorage secureStorage = FlutterSecureStorage();

// generowanie tokenu
Future<void> generateNewToken() async {
  final newToken = Uuid().v4();
  await secureStorage.write(
      key: 'token', value: newToken); // zapis tokenu z secure storage
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
