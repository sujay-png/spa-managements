class CustomerModel {
  final int? id;
  final String name;
  final String email;
  final String phoneno;
  final DateTime? dob;
  final String address;
  final String notes;

  const CustomerModel({
    this.id,
    required this.name,
    required this.email,
    required this.phoneno,
    this.dob,
    required this.address,
    required this.notes,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int?,
      name: json['customer_name']?.toString() ?? '',
      email: json['customer_email']?.toString() ?? '',
      phoneno: json['customer_phone']?.toString() ?? '',
      dob: json['customer_dob'] != null
          ? DateTime.parse(json['customer_dob'].toString())
          : null,
      address: json['customer_address']?.toString() ?? '',
      notes: json['customer_note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_name': name,
      'customer_email': email,
      'customer_phone': phoneno,
      'customer_dob': dob?.toIso8601String(),
      'customer_address': address,
      'customer_note': notes,
    };
  }

  CustomerModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneno,
    DateTime? dob,
    String? address,
    String? notes,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneno: phoneno ?? this.phoneno,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }
}