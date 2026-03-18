class Patient {
  final String id;
  final String name;
  final int age;
  final String condition;
  final String? phoneNumber;
  final String? email;
  final String? address;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.condition,
    this.phoneNumber,
    this.email,
    this.address,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      condition: json['condition'] ?? '',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      address: json['address'],
    );
  }

  // Fixed: Return the phoneNumber property instead of null
  String get phone => phoneNumber ?? 'Not provided';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'condition': condition,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
    };
  }
}