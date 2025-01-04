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
        syncLocalNotesWithServer();
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
  Future<void> syncLocalNotesWithServer() async {
    final prefs = await SharedPreferences.getInstance();
    // Zapisz wszystkie notatki, w tym te z serwera
    await prefs.setStringList('notes', notes);

    // Dodatkowy krok: zapisz te notatki, które zostały pobrane z serwera, ale nie były wcześniej zapisane lokalnie
    List<String> serverNotesNotSavedLocally = notes
        .where((note) => !prefs.getStringList('notes')!.contains(note))
        .toList();
    if (serverNotesNotSavedLocally.isNotEmpty) {
      // Zapisz notatki, które były tylko na serwerze, ale nie były jeszcze zapisane lokalnie
      await prefs.setStringList('notes',
          [...prefs.getStringList('notes')!, ...serverNotesNotSavedLocally]);
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
