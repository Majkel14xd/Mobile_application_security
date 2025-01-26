import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/io_client.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  // konfiguracja klienta http z SLL certificate pinning
  Future<IOClient> getClientWithCert() async {
    final certData =
        await DefaultAssetBundle.of(context).load('Certs/cert.pem');
    final securityContext = SecurityContext(withTrustedRoots: false);
    securityContext.setTrustedCertificatesBytes(certData.buffer.asUint8List());

    final httpClient = HttpClient(context: securityContext)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        final expectedFingerprint = dotenv.env['EXPECTED_FINGERPRINT'];
        final fingerprint = sha256.convert(cert.der).toString();
        print('Certificate fingerprint: $fingerprint');
        if (fingerprint != expectedFingerprint) {
          print('MITM attack detected: $host');
          return false;
        }
        return true;
      };

    return IOClient(httpClient);
  }

  // pobranie tokenu z secureStorage
  Future<String> _getToken() async {
    String? token = await _secureStorage.read(key: 'token');
    print('Token retrieved: $token');
    return token ?? '';
  }

  Future<void> fetchNotesFromServer() async {
    final url = Uri.parse('https://192.168.100.117:5000/api/data');
    try {
      final client = await getClientWithCert();
      final token = await _getToken();
      print('Using token: $token');

      final response = await client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> serverNotes = List<String>.from(
            data.map((item) => item['message'] ?? 'No message'));

        setState(() {
          notes.addAll(serverNotes.where((note) => !notes.contains(note)));
        });

        await _secureStorage.write(key: 'notes', value: jsonEncode(notes));
      } else {
        print('Failed to fetch notes: ${response.statusCode}');
        throw Exception('Failed to fetch notes: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error fetching notes. Please try again later.')),
      );
    }
  }

  Future<void> fetchNotesLocally() async {
    String storedNotes = await _secureStorage.read(key: 'notes') ??
        '[]'; //pobranie z secureStorage
    print('Fetched local notes: $storedNotes');
    setState(() {
      notes = List<String>.from(jsonDecode(storedNotes));
    });
  }

  //  synchronizacja notatek lokalnych z serwerem
  Future<void> syncLocalNotesWithServer(List<String> serverNotes) async {
    // sprawdzenie notatek lokalnych, które nie są na serwerze i na odwrot
    List<String> localNotesNotOnServer =
        notes.where((note) => !serverNotes.contains(note)).toList();
    for (var note in localNotesNotOnServer) {
      await addNoteToServer(note);
    }
    List<String> serverNotesNotOnDevice =
        serverNotes.where((note) => !notes.contains(note)).toList();
    setState(() {
      notes.addAll(serverNotesNotOnDevice);
    });

    await _secureStorage.write(key: 'notes', value: jsonEncode(notes));
  }

  Future<void> addNoteToServer(String note) async {
    final token = await _getToken();

    final url = Uri.parse('https://192.168.100.117:5000/api/data');
    try {
      final client = await getClientWithCert();
      final response = await client.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'message': note}),
      );

      if (response.statusCode == 200) {
        print('Note added to server');
      } else {
        print('Failed to add note to server');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  Future<void> deleteNoteFromServer(String note) async {
    final token = await _getToken();

    final url = Uri.parse('https://192.168.100.117:5000/api/data/$note');
    try {
      final client = await getClientWithCert();
      final response = await client.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // po usunieciu z serwera usuwa lokalnie
        setState(() {
          notes.remove(note); // usuniecie z listy
        });

        // aktualizacja secureStorage po usunieciu
        String updatedNotes = jsonEncode(notes);
        await _secureStorage.write(key: 'notes', value: updatedNotes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete note!')),
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
        title: const Text('Read Notes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: notes.isEmpty
            ? const Center(child: Text('Brak notatek'))
            : ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(notes[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        deleteNoteFromServer(notes[index]);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
