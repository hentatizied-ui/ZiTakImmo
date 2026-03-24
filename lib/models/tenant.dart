class Tenant {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String? buildingId;
  final String? lotId;
  final DateTime startDate;
  final double deposit;

  Tenant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    this.buildingId,
    this.lotId,
    required this.startDate,
    required this.deposit,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'email': email,
    'buildingId': buildingId,
    'lotId': lotId,
    'startDate': startDate.toIso8601String(),
    'deposit': deposit,
  };

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
    id: json['id'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    phone: json['phone'],
    email: json['email'],
    buildingId: json['buildingId'],
    lotId: json['lotId'],
    startDate: DateTime.parse(json['startDate']),
    deposit: json['deposit'],
  );
}