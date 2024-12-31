import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'dart:convert';

class ReadNotesScreen extends StatefulWidget {
  const ReadNotesScreen({super.key});

  @override
  _ReadNotesScreenState createState() => _ReadNotesScreenState();
}

class _ReadNotesScreenState extends State<ReadNotesScreen> {
  List<String> notes = [];

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<IOClient> getClientWithCert() async {
    final certData =
        await DefaultAssetBundle.of(context).loadString('cert.pem');

    final securityContext = SecurityContext(withTrustedRoots: false);
    securityContext.setTrustedCertificatesBytes(certData.codeUnits);

    final httpClient = HttpClient(context: securityContext)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    return IOClient(httpClient);
  }

  Future<void> fetchNotes() async {
    final url = Uri.parse('https://10.0.0.3:5000/api/notes');
    try {
      final client = await getClientWithCert();
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notes = List<String>.from(
              data.map((item) => item['message'] ?? 'No message'));
        });
      }
    } catch (e) {
      print('Exception: $e');
    }
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
            ? const CircularProgressIndicator()
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
