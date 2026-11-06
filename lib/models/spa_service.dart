class ServiceOption {
  final int? id;
  final String label;
  final int duration;
  final int price;

  const ServiceOption({
    this.id,
    required this.label,
    required this.duration,
    required this.price,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceOption &&
          other.label == label &&
          other.duration == duration &&
          other.price == price &&
          other.id == id;

  @override
  int get hashCode => Object.hash(id, label, duration, price);
}

class SpaService {
  final String id;
  final String title;
  final String category;
  final String description;
  final List<ServiceOption> options;

  const SpaService({
    required this.id,
    required this.title,
    this.category = 'General',
    required this.description,
    required this.options,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SpaService && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
