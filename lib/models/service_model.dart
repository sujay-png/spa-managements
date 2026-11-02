class ServiceModel {
  final int? id;
  final String serviceName;
  final String designation;
  final String duration;
  final double price;
  final int? businessRef;

  const ServiceModel({
    this.id,
    required this.serviceName,
    required this.designation,
    required this.duration,
    required this.price,
    this.businessRef,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      final sanitized = value.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(sanitized) ?? 0.0;
    }

    return ServiceModel(
      id: parseInt(json['id']),
      serviceName: json['service_name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      businessRef: parseInt(json['business_ref']),
      price: parseDouble(json['price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_name': serviceName,
      'designation': designation,
      'duration': duration,
      'price': price,
      'business_ref': businessRef,
    };
  }

  ServiceModel copyWith({
    int? id,
    String? serviceName,
    String? designation,
    String? duration,
    double? price,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      designation: designation ?? this.designation,
      duration: duration ?? this.duration,
      price: price ?? this.price,
    );
  }
}
