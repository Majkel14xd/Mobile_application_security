import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SaveNotes extends StatefulWidget {
  const SaveNotes({super.key});

  @override
  _SaveNotesState createState() => _SaveNotesState();
}

class _SaveNotesState extends State<SaveNotes> {
  TextEditingController noteController = TextEditingController();

  Future<void> saveNote() async {
    final url = Uri.parse('http://10.100.3.154:5000/api/data');
    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'data': noteController.text}));

      if (response.statusCode == 200) {
        setState(() {
          noteController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully!')),
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
