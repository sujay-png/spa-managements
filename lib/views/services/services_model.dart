class ServiceModel {
  final String title;
  final String category;
  final String duration;
  final int price;
  final int bookings;
  final int revenue;
  final String status;

  const ServiceModel({
    required this.title,
    required this.category,
    required this.duration,
    required this.price,
    required this.bookings,
    required this.revenue,
    required this.status,
  });
}