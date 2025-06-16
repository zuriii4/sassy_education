import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/screens/teacher/material_steps/previews/puzzle_preview.dart';
import 'package:sassy/screens/teacher/material_steps/previews/quiz_preview.dart';
import 'package:sassy/screens/teacher/material_steps/previews/word_jumble_preview.dart';
import 'package:sassy/screens/teacher/material_steps/previews/connections_preview.dart';

class MaterialPreviewBuilder {
  static Widget buildPreview(String type, Map<String, dynamic> content, ApiService apiService, {bool isInteractive = false}) {
    String normalizedType = type.toLowerCase().trim();
    
    switch (normalizedType) {
      case 'puzzle':
        return _buildPuzzlePreview(content, apiService, isInteractive);
      case 'quiz':
        return _buildQuizPreview(content, apiService, isInteractive);
      case 'word-jumble':
        return _buildWordJumblePreview(content, isInteractive);
      case 'connection':
        return _buildConnectionsPreview(content, isInteractive);
      default:
        return Center(
          child: Text('Nepodporovaný typ obsahu: $type'),
        );
    }
  }
  
  static Widget _buildPuzzlePreview(Map<String, dynamic> content, ApiService apiService, bool isInteractive) {
    final String? imagePath = content['image'];
    final gridData = content['grid'] ?? {};
    final int gridSize = gridData['columns'] ?? 3;
    
    if (imagePath == null) {
      return const Center(child: Text('Chýba obrázok pre puzzle'));
    }
    
    return PuzzlePreview(
      imagePath: imagePath,
      gridSize: gridSize,
      apiService: apiService,
      isInteractive: isInteractive,
    );
  }
  
  static Widget _buildQuizPreview(Map<String, dynamic> content, ApiService apiService, bool isInteractive) {
    final List<Map<String, dynamic>> questions = 
        List<Map<String, dynamic>>.from(content['questions'] ?? []);
    
    if (questions.isEmpty) {
      return const Center(child: Text('Žiadne otázky neboli nájdené'));
    }
    
    return QuizPreview(
      questions: questions,
      apiService: apiService,
      isInteractive: isInteractive,
    );
  }
  
  static Widget _buildWordJumblePreview(Map<String, dynamic> content, bool isInteractive) {
    final List<String> words = List<String>.from(content['words'] ?? []);
    final List<String> correctOrder = List<String>.from(content['correct_order'] ?? words);
    
    if (words.isEmpty) {
      return const Center(child: Text('Žiadne slová neboli nájdené'));
    }
    
    return WordJumblePreview(
      words: words,
      correctOrder: correctOrder,
      isInteractive: isInteractive,
    );
  }
  
  static Widget _buildConnectionsPreview(Map<String, dynamic> content, bool isInteractive) {
    final List<dynamic> rawPairs = content['pairs'] ?? [];
    final List<Map<String, String>> pairs = rawPairs
        .map((pair) => {
              'left': pair['left'] as String,
              'right': pair['right'] as String,
            })
        .toList();
    
    if (pairs.isEmpty) {
      return const Center(child: Text('Žiadne páry neboli nájdené'));
    }
    
    return ConnectionsPreview(
      pairs: pairs,
      isInteractive: isInteractive,
    );
  }
}