import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/io_client.dart';
import 'package:crypto/crypto.dart';

class ReadNotes extends StatefulWidget {
  const ReadNotes({super.key});

  @override
  _ReadNotesState createState() => _ReadNotesState();
}

class _ReadNotesState extends State<ReadNotes> {
  List<String> notes = [];
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchNotesLocally();
    fetchNotesFromServer();
  }

  Future<IOClient> getClientWithCert() async {
    final certData = await DefaultAssetBundle.of(context).load('cert.pem');
    final securityContext = SecurityContext(withTrustedRoots: false);
    securityContext.setTrustedCertificatesBytes(certData.buffer.asUint8List());

    final httpClient = HttpClient(context: securityContext)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        const expectedFingerprint =
            'a4cb2c79cd6d5262a567090c31d2dfa4f90c43b37b92c14aad374c234f57cc6c';
        final fingerprint = sha256.convert(cert.der).toString();
        print(
            'Certificate fingerprint: $fingerprint'); // Debugowanie fingerprintu
        if (fingerprint != expectedFingerprint) {
          print('MITM attack detected: $host');
          return false;
        }
        return true;
      };

    return IOClient(httpClient);
  }

  Future<String> _getToken() async {
    String? token = await _secureStorage.read(key: 'token');
    print('Token retrieved: $token'); // Debugowanie tokenu
    return token ?? '';
  }

  Future<void> fetchNotesFromServer() async {
    final url = Uri.parse('https://192.168.100.117:5000/api/data');
    try {
      final client = await getClientWithCert();
      final token = await _getToken();
      print('Using token: $token'); // Debugowanie tokenu

      final response = await client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      print(
          'Response status: ${response.statusCode}'); // Debugowanie statusu odpowiedzi
      print('Response body: ${response.body}'); // Debugowanie treści odpowiedzi

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> serverNotes = List<String>.from(
            data.map((item) => item['message'] ?? 'No message'));

        setState(() {
          notes.addAll(serverNotes.where((note) => !notes.contains(note)));
        });

        await _secureStorage.write(key: 'notes', value: jsonEncode(notes));
      } else {
        print(
            'Failed to fetch notes: ${response.statusCode}'); // Debugowanie błędu
        throw Exception('Failed to fetch notes: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred: $e'); // Debugowanie wyjątków
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error fetching notes. Please try again later.')),
      );
    }
  }

  Future<void> fetchNotesLocally() async {
    String storedNotes = await _secureStorage.read(key: 'notes') ?? '[]';
    print('Fetched local notes: $storedNotes'); // Debugowanie lokalnych notatek
    setState(() {
      notes = List<String>.from(jsonDecode(storedNotes));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Read Notes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: notes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(notes[index]),
                  );
                },
              ),
      ),
    );
  }
}
