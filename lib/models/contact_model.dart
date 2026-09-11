class ContactModel {
  final String id;
  final String name;
  final String phoneNumber;

  ContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  factory ContactModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ContactModel(
      id: id,
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }
}