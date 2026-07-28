class ServiceOption {
  final String label;
  final int duration;
  final int price;

  const ServiceOption({
    required this.label,
    required this.duration,
    required this.price,
  });
}

class SpaService {
  final String id;
  final String title;
  final String description;
  final List<ServiceOption> options;

  const SpaService({
    required this.id,
    required this.title,
    required this.description,
    required this.options,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SpaService && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
