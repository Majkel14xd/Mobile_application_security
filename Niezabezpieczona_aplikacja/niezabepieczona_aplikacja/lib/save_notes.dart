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

  Future<void> saveNote() async {
    final token = await _getToken();
    print("Token: $token"); // loging tokena

    final noteText = noteController.text.trim(); // usuniecie bialych znakow
    if (noteText.isEmpty) {
      // obsluga pustej notatki
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note cannot be empty!')),
      );
      return;
    }

    final url = Uri.parse('http://192.168.100.117:5000/api/data');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // dodanie tokena w naglowku
        },
        body: jsonEncode({'note': noteText}),
      );

      // "logi"
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        saveNoteLocally(noteText);

        setState(() {
          noteController.clear(); // czyszczenie pola tekstowego po zapisaniu
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully!')),
        );
      } else {
        // blad autoryzacji
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return token;
  }

  Future<void> saveNoteLocally(String note) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentNotes = prefs.getStringList('notes') ?? [];
    currentNotes.add(note);

    // zapis listy notatek z powrotem w SharedPreferences
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
