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
    loadLocalNotes(); // Załaduj notatki lokalnie
    fetchNotes(); // Pobierz notatki z serwera
  }

  // Funkcja do ładowania lokalnych notatek
  Future<void> loadLocalNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? localNotes = prefs.getStringList('notes');
    if (localNotes != null) {
      setState(() {
        notes = localNotes;
      });
    }
  }

  // Funkcja do pobierania notatek z serwera
  Future<void> fetchNotes() async {
    final token = await _getToken(); // Pobierz token z SharedPreferences

    final url = Uri.parse('http://192.168.100.117:5000/api/data');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Dodaj token w nagłówku
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> serverNotes = List<String>.from(
            data.map((item) => item['message'] ?? 'No message'));

        setState(() {
          // Dodaj tylko nowe notatki z serwera, które jeszcze nie są zapisane lokalnie
          notes.addAll(serverNotes.where((note) => !notes.contains(note)));
        });

        // Synchronizuj lokalne notatki z serwerem
        syncLocalNotesWithServer(serverNotes);
      } else {
        // Obsługa błędu autoryzacji
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized!')),
        );
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  // Funkcja do pobrania tokena z SharedPreferences
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return token;
  }

  // Funkcja do synchronizowania lokalnych notatek z serwerem
  Future<void> syncLocalNotesWithServer(List<String> serverNotes) async {
    final prefs = await SharedPreferences.getInstance();
    // Zapisz wszystkie notatki, w tym te z serwera
    await prefs.setStringList('notes', notes);

    // 1. Sprawdzenie, czy są notatki lokalne, które nie istnieją na serwerze
    List<String> localNotesNotOnServer =
        notes.where((note) => !serverNotes.contains(note)).toList();

    for (var note in localNotesNotOnServer) {
      await addNoteToServer(note); // Dodaj lokalną notatkę na serwer
    }

    // 2. Sprawdzenie, czy są notatki na serwerze, których nie ma lokalnie
    List<String> serverNotesNotOnDevice =
        serverNotes.where((note) => !notes.contains(note)).toList();

    setState(() {
      // Dodaj notatki z serwera, które nie były zapisane lokalnie
      notes.addAll(serverNotesNotOnDevice);
    });

    // Zaktualizuj lokalne notatki po synchronizacji
    await prefs.setStringList('notes', notes);
  }

  // Funkcja do dodawania notatki na serwer
  Future<void> addNoteToServer(String note) async {
    final token = await _getToken(); // Pobierz token z SharedPreferences

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

  // Funkcja do usuwania notatki z serwera oraz lokalnie
  Future<void> deleteNoteFromServer(String note) async {
    final token = await _getToken(); // Pobierz token z SharedPreferences

    final url = Uri.parse('http://192.168.100.117:5000/api/data/$note');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Usuwamy notatkę lokalnie po jej usunięciu z serwera
        setState(() {
          notes.remove(note); // Usuń notatkę z listy
        });

        // Zaktualizuj SharedPreferences po usunięciu notatki lokalnie
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
                        // Wywołaj funkcję usuwania notatki
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
