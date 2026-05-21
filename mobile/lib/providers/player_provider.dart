import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/player_technical_note.dart';
import '../services/api_service.dart';

class PlayerProvider with ChangeNotifier {
  List<PlayerTechnicalNote> _notes = [];
  bool _isLoading = false;

  List<PlayerTechnicalNote> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> loadPlayerNotes(int playerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/encadrant/players/$playerId/notes'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _notes = data.map((json) => PlayerTechnicalNote.fromJson(json)).toList();
      } else {
        print('Error loading notes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createNote(int playerId, PlayerTechnicalNote note) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/encadrant/players/$playerId/notes'),
        headers: await ApiService.getHeaders(),
        body: json.encode(note.toJson()),
      );

      if (response.statusCode == 200) {
        final newNote = PlayerTechnicalNote.fromJson(json.decode(response.body));
        _notes.insert(0, newNote);
        notifyListeners();
        return true;
      } else {
        print('Error creating note: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error creating note: $e');
      return false;
    }
  }
}
