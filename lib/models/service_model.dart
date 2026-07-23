class ServiceModel {
  final int? id;
  final String serviceName;
  final String designation;
  final String duration;
  final double price;

  const ServiceModel({
     this.id,
    required this.serviceName,
    required this.designation,
    required this.duration,
    required this.price,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
        id: json['id'] as int?,
      serviceName: json['service_name'] ?? '',
      designation: json['designation'] ?? '',
      duration: json['duration'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

 Map<String, dynamic> toJson() {
  return {
    'service_name': serviceName,
    'designation': designation,
    'duration': duration,
    'price': price,
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