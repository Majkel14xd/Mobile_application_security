import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'dart:convert';

class SaveNotesScreen extends StatefulWidget {
  const SaveNotesScreen({super.key});

  @override
  _SaveNotesScreenState createState() => _SaveNotesScreenState();
}

class _SaveNotesScreenState extends State<SaveNotesScreen> {
  TextEditingController noteController = TextEditingController();

  Future<IOClient> getClientWithCert() async {
    final certData =
        await DefaultAssetBundle.of(context).loadString('cert.pem');

    final securityContext = SecurityContext(withTrustedRoots: true);
    securityContext.setTrustedCertificatesBytes(certData.codeUnits);

    final httpClient = HttpClient(context: securityContext)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    return IOClient(httpClient);
  }

  Future<void> saveNote() async {
    final url = Uri.parse('https://10.0.0.3:5000/api/notes');
    try {
      final client = await getClientWithCert();
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'note': noteController.text}),
      );

      if (response.statusCode == 200) {
        setState(() {
          noteController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully!')),
        );
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Notes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Enter your note',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: saveNote,
              child: const Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}
