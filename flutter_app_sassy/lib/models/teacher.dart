class Teacher {
  final String id;
  final String name;
  final String email;
  final String specialization;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.specialization,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      specialization: json['specialization'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'specialization': specialization,
    };
  }
  
  Teacher copyWith({
    String? name,
    String? email,
    String? specialization,
  }) {
    return Teacher(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      specialization: specialization ?? this.specialization,
    );
  }
}