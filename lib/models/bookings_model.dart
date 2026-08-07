

class BookingsModel {
  int? id;
  int? businessRef;

  String? customerRef;
  String? serviceRef;
  String? therapistRef;

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
      return 'Completed';

    case 'cancelled':
      return 'Cancelled';

    default:
      return statusrequired;
  }
}


  factory BookingsModel.fromMap(Map<String, dynamic> map) {
  return BookingsModel(
    id: map['id'],
    businessRef: map['business_ref'],

    customerRef: map['customer_ref'],
    serviceRef: map['services'],
    therapistRef: map['therapist'],

    customer: map['customer_ref'] ?? '',
    servicename: map['services'] ?? '',
    therapistname: map['therapist'] ?? '',

    bookingdate: map['available_slot'] != null
        ? DateTime.parse(map['available_slot'])
        : DateTime.now(),

    timeslot: map['confirmed_time'] ?? '',
    bookingdetails: map['requirements_booking'] ?? '',
    statusrequired: map['booking_status'] ?? 'Pending',

    startTime: map['start_time'] != null
        ? DateTime.parse(map['start_time'])
        : null,

    endTime: map['end_time'] != null
        ? DateTime.parse(map['end_time'])
        : null,

    duration: map['duration'],
    // Inside BookingsModel.fromMap:
servicePrice: map['service_price']?.toString() ?? map['servicePrice']?.toString() ?? '0',
    serviceOptionId: map['service_option_id'],
    emailSent: map['email_sent'] ?? false,
  );
}

 Map<String, dynamic> toMap() {
  return {
    "business_ref": businessRef,
    "customer_ref": customer,
    "services": servicename,
    "therapist": therapistname,
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
