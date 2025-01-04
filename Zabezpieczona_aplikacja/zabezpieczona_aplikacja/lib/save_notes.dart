import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/io_client.dart';
import 'package:crypto/crypto.dart';

class SaveNotes extends StatefulWidget {
  const SaveNotes({super.key});

  @override
  _SaveNotesState createState() => _SaveNotesState();
}

class _SaveNotesState extends State<SaveNotes> {
  TextEditingController noteController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Method to configure the HTTP client with SSL certificate pinning
  Future<IOClient> getClientWithCert() async {
    final certData = await DefaultAssetBundle.of(context).load('cert.pem');
    final securityContext = SecurityContext(withTrustedRoots: false);
    securityContext.setTrustedCertificatesBytes(certData.buffer.asUint8List());

    final httpClient = HttpClient(context: securityContext)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Certificate pinning logic
        const expectedFingerprint =
            'a4cb2c79cd6d5262a567090c31d2dfa4f90c43b37b92c14aad374c234f57cc6c';
        final fingerprint = sha256.convert(cert.der).toString();
        if (fingerprint != expectedFingerprint) {
          print('MITM attack detected: $host');
          return false; // Block connection if fingerprint doesn't match
        }
        return true; // Accept valid certificate
      };

    return IOClient(httpClient);
  }

  // Method to retrieve the saved token for authentication
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'token');
  }

  // Method to save a note to the server and store it locally
  Future<void> saveNote() async {
    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found!')),
      );
      return;
    }

    final url = Uri.parse('https://192.168.100.117:5000/api/data');
    try {
      final client = await getClientWithCert();
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'note': noteController.text}),
      );

      if (response.statusCode == 200) {
        String existingNotes = await _secureStorage.read(key: 'notes') ?? '[]';
        List<dynamic> notesList = jsonDecode(existingNotes);
        notesList.add(noteController.text);
        await _secureStorage.write(key: 'notes', value: jsonEncode(notesList));

        setState(() {
          noteController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error saving note. Please try again later.')),
      );
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
