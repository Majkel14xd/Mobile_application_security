import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/io_client.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SaveNotes extends StatefulWidget {
  const SaveNotes({super.key});

  @override
  _SaveNotesState createState() => _SaveNotesState();
}

class _SaveNotesState extends State<SaveNotes> {
  TextEditingController noteController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // konfiguracja klienta http z SLL certificate pinning
  Future<IOClient> getClientWithCert() async {
    final certData =
        await DefaultAssetBundle.of(context).load('Certs/cert.pem');
    final securityContext = SecurityContext(withTrustedRoots: false);
    securityContext.setTrustedCertificatesBytes(certData.buffer.asUint8List());

    final httpClient = HttpClient(context: securityContext)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // logika certificate pinning
        final expectedFingerprint = dotenv.env['EXPECTED_FINGERPRINT'];
        final fingerprint = sha256.convert(cert.der).toString();
        if (fingerprint != expectedFingerprint) {
          print('MITM attack detected: $host');
          return false; // blok jak fingerprinty sie nie zgadzaja
        }
        return true; // przyjecie zgodnego certyfikatu
      };

    return IOClient(httpClient);
  }

  // pobranie tokenu z secureStorage
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'token');
  }

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
