class Student {
  final String id;
  final String name;
  final String email;
  final String notes;
  final String status;
  final String needsDescription;
  final String lastActive;
  final bool hasSpecialNeeds;
  final DateTime? dateOfBirth;
  
  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.notes,
    required this.status,
    required this.needsDescription,
    required this.lastActive,
    required this.hasSpecialNeeds,
    this.dateOfBirth,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['dateOfBirth'] != null) {
      try {
        parsedDate = DateTime.parse(json['dateOfBirth']);
      } catch (e) {
        parsedDate = null;
      }
    }
    
    return Student(
      id: json['id'],
      name: json['name'],
      email: json['email'] ?? '',
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'Aktívny',
      needsDescription: json['needsDescription'] ?? '',
      lastActive: json['lastActive'] ?? 'Nezname',
      hasSpecialNeeds: json['hasSpecialNeeds'] ?? false,
      dateOfBirth: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'notes': notes,
      'status': status,
      'needsDescription': needsDescription,
      'lastActive': lastActive,
      'hasSpecialNeeds': hasSpecialNeeds,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
    };
  }
}