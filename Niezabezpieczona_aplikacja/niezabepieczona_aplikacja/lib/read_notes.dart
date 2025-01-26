import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReadNotes extends StatefulWidget {
  const ReadNotes({super.key});

  @override
  _ReadNotesState createState() => _ReadNotesState();
}

class _ReadNotesState extends State<ReadNotes> {
  List<String> notes = [];

  @override
  void initState() {
    super.initState();
    loadLocalNotes(); // zaladowanie notatek lokalnych
    fetchNotes(); // pobranie notatek z serwera
  }

  Future<void> loadLocalNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? localNotes = prefs.getStringList('notes');
    if (localNotes != null) {
      setState(() {
        notes = localNotes;
      });
    }
  }

  Future<void> fetchNotes() async {
    final token = await _getToken();

    final url = Uri.parse('http://192.168.100.117:5000/api/data');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // dodanie tokena do naglowka
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> serverNotes = List<String>.from(
            data.map((item) => item['message'] ?? 'No message'));

        setState(() {
          // dodanie nowych notatek z serwera
          notes.addAll(serverNotes.where((note) => !notes.contains(note)));
        });

        syncLocalNotesWithServer(serverNotes);
      } else {
        // blad autoryzacji
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized!')),
        );
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  // pobranie tokenu z SharedPreferences
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return token;
  }

  Future<void> syncLocalNotesWithServer(List<String> serverNotes) async {
    final prefs = await SharedPreferences.getInstance();
    // Zapisz wszystkie notatki, w tym te z serwera
    await prefs.setStringList('notes', notes);

    // sprawdzenie czy sa notatki lokalne,ktorych nie ma na serwerze i na odwrot
    List<String> localNotesNotOnServer =
        notes.where((note) => !serverNotes.contains(note)).toList();
    for (var note in localNotesNotOnServer) {
      await addNoteToServer(note); // Dodaj lokalną notatkę na serwer
    }
    List<String> serverNotesNotOnDevice =
        serverNotes.where((note) => !notes.contains(note)).toList();
    setState(() {
      // dodanie serwerowych notatek
      notes.addAll(serverNotesNotOnDevice);
    });

    // aktualizacja lokalnych po synchronizacji
    await prefs.setStringList('notes', notes);
  }

  Future<void> addNoteToServer(String note) async {
    final token = await _getToken();

    final url = Uri.parse('http://192.168.100.117:5000/api/data');
    try {
      final response = await http.post(
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

    final url = Uri.parse('http://192.168.100.117:5000/api/data/$note');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notes.remove(note); // Usuń notatkę z listy
        });

        // aktualizacja SharedPreferences po usunięciu notatki lokalnie
        final prefs = await SharedPreferences.getInstance();
        List<String> updatedNotes = prefs.getStringList('notes') ?? [];
        updatedNotes.remove(note);
        await prefs.setStringList('notes', updatedNotes);

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
