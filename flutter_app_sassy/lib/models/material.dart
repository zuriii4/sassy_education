class TaskModel {
  String title;
  String description;
  String type;
  Map<String, dynamic> content;
  List<String> assignedTo;
  List<String> assignedGroups;

  TaskModel({
    required this.title,
    required this.description,
    required this.type,
    required this.content,
    required this.assignedTo,
    required this.assignedGroups,
  });


  void addQuizQuestion(String text, List<Map<String, dynamic>> answers, {String? image}) {
    if (type != 'quiz') return;
    
    if (!content.containsKey('questions')) {
      content['questions'] = [];
    }
    
    final question = {
      'text': text,
      'answers': answers,
    };
    
    if (image != null) {
      question['image'] = image;
    }
    
    content['questions'].add(question);
  }
  
  void setPuzzleContent(String image, int columns, int rows) {
    if (type != 'puzzle') return;
    
    content = {
      'image': image,
      'grid': {
        'columns': columns,
        'rows': rows
      }
    };
  }
  
  void setWordJumbleContent(List<String> words, List<String> correctOrder) {
    if (type != 'word-jumble') return;
    
    content = {
      'words': words,
      'correct_order': correctOrder
    };
  }
  
  void setConnectionContent(List<Map<String, String>> pairs) {
    if (type != 'connection') return;
    
    content = {
      'pairs': pairs
    };
  }
  
  bool isContentValid() {
    switch (type) {
      case 'quiz':
        return content.containsKey('questions') && 
               (content['questions'] as List).isNotEmpty;
      case 'puzzle':
        return content.containsKey('image') && 
               content.containsKey('grid');
      case 'word-jumble':
        return content.containsKey('words') && 
               content.containsKey('correct_order');
      case 'connection':
        return content.containsKey('pairs') && 
               (content['pairs'] as List).isNotEmpty;
      default:
        return false;
    }
  }
}