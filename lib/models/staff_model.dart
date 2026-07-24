class StaffModel {
  final int? id;
  final String name;
  final String email;
  final String phno;
  final String designation;
  final String specialization;
  final int? businessRef;

  const StaffModel({
    this.id,
    required this.name,
    required this.email,
    required this.phno,
    required this.designation,
    required this.specialization,
    this.businessRef,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as int,
      name: json['name'],
      email: json['email'],
      phno: json['phone'],
      designation: json['designation'],
      specialization: json['job_title'],
      businessRef: json['business_ref'] as int?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phno,
      'designation': designation,
      'job_title': specialization,
      'business_ref': businessRef,
    };
  }

  StaffModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phno,
    String? designation,
    String? specialization,
  }) {
    return StaffModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phno: phno ?? this.phno,
      designation: designation ?? this.designation,
      specialization: specialization ?? this.specialization,
    );
  }
}
