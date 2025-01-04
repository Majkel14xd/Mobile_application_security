import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SaveNotes extends StatefulWidget {
  const SaveNotes({super.key});

  @override
  _SaveNotesState createState() => _SaveNotesState();
}

class _SaveNotesState extends State<SaveNotes> {
  TextEditingController noteController = TextEditingController();

  // Funkcja do zapisywania notatki na serwerze oraz lokalnie
  Future<void> saveNote() async {
    final token = await _getToken(); // Pobierz token z SharedPreferences

    final url = Uri.parse('http://192.168.100.117:5000/api/data');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Dodaj token w nagłówku
        },
        body: jsonEncode({'data': noteController.text}),
      );

      if (response.statusCode == 200) {
        // Zapisz notatkę lokalnie
        saveNoteLocally(noteController.text);

        // Wyczyść pole tekstowe po zapisaniu
        setState(() {
          noteController.clear();
        });

        // Pokaż komunikat o sukcesie
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully!')),
        );
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

  // Funkcja do zapisywania notatki lokalnie
  Future<void> saveNoteLocally(String note) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentNotes = prefs.getStringList('notes') ?? [];

    // Dodaj nową notatkę do listy
    currentNotes.add(note);

    // Zapisz listę notatek z powrotem w SharedPreferences
    await prefs.setStringList('notes', currentNotes);
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
                hintText: 'Enter note to save',
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
