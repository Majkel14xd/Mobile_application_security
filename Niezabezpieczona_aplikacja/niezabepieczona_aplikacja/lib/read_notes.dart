import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    final url = Uri.parse('http://10.100.3.154:5000/api/data');
    try {
      final response = await http.get(url);

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
