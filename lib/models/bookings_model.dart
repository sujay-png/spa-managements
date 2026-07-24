

class BookingsModel {
  int? id;
  int? businessRef;
  int? customerRef;
  int? serviceRef;
  int? therapistRef;

  String customer;
  String servicename;
  String therapistname;

  String? custphone;
  String? serviceDuration;
  String? servicePrice;

  DateTime bookingdate;
  String timeslot;
  String bookingdetails;
  String statusrequired;

  DateTime? startTime;
  DateTime? endTime;
  int? duration;
  int? serviceOptionId;
  bool emailSent;

  BookingsModel({
    this.id,
    this.businessRef,
    this.customerRef,
    this.serviceRef,
    this.therapistRef,
    required this.customer,
    required this.servicename,
    required this.therapistname,
    this.custphone,
    this.serviceDuration,
    this.servicePrice,
    required this.bookingdate,
    required this.timeslot,
    required this.bookingdetails,
    required this.statusrequired,
    this.startTime,
    this.endTime,
    this.duration,
    this.serviceOptionId,
    this.emailSent = false,
  });
  

String get statusLabel {
  switch (statusrequired.toLowerCase()) {
    case 'pending':
      return 'Pending';
    case 'confirmed':
      return 'Confirmed';
    case 'complete':
    case 'completed':
      return 'Complete';
    case 'cancelled':
      return 'Cancelled';
    default:
      return statusrequired;
  }
}


  factory BookingsModel.fromMap(Map<String, dynamic> map) {
    return BookingsModel(
      id: map['id'],
      customerRef: map['customer_ref'],
      therapistRef: map['therapist'],
      serviceRef: map['services'],
      customer: (map['Customers'] as Map?)?['customer_name'] ?? '',
      custphone: (map['Customers'] as Map?)?['customer_phone'] ?? '',
      serviceDuration:
          (map['service'] as Map?)?['service_duration']?.toString(),
      servicePrice:
          (map['service'] as Map?)?['service_cost']?.toString(),
      servicename: (map['service'] as Map?)?['service_name'] ?? '',
      bookingdate: map['available_slot'] != null
          ? DateTime.parse(map['available_slot'])
          : DateTime.now(),
      timeslot: map['confirmed_time'] ?? '',
      bookingdetails: map['requirements_booking'] ?? '',
      therapistname: (map['Therapist'] as Map?)?['name'] ?? '',
      statusrequired: map['booking_status'] ?? 'pending', // ✅ correct
      businessRef: map['business_ref'] as int?,

    );
  }

 Map<String, dynamic> toMap() {
  return {
    "business_ref": businessRef,
    "customer_ref": customerRef,
    "services": serviceRef,
    "therapist": therapistRef,
    "available_slot": bookingdate.toIso8601String(),
    "confirmed_time": timeslot,
    "requirements_booking": bookingdetails,
    "booking_status": statusrequired,
    "start_time": startTime?.toIso8601String(),
    "end_time": endTime?.toIso8601String(),
    "duration": duration,
    "service_option_id": serviceOptionId,
    "email_sent": emailSent,
  };
}
}
