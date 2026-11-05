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
  String? paymentStatus;
  String? paymentMethod;
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
    this.paymentStatus,
    this.paymentMethod,
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

  String get paymentStatusLabel {
    switch (paymentStatus?.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'unpaid':
        return 'Unpaid';
      default:
        return paymentStatus ?? '';
    }
  }

  factory BookingsModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    final rawPrice = map['total_amount'] ??
        map['rate'] ??
        map['paid_amount'] ??
        map['price'] ??
        map['service_price'];

    return BookingsModel(
      id: parseInt(map['id']),
      businessRef: parseInt(map['business_ref']),

      // IDs
      customerRef: parseInt(map['customer_id'] ?? map['customer_ref']),
      serviceRef: parseInt(map['service_id'] ?? map['service_option_id']),
      therapistRef: parseInt(map['staff_id'] ?? map['therapist_id']),

      // Names
      customer: map['customer_ref']?.toString() ?? '',
      servicename: map['services']?.toString() ?? '',
      therapistname: map['therapist']?.toString() ?? '',

      bookingdate: parseDate(map['available_slot']) ??
          parseDate(map['check_in_at']) ??
          DateTime.now(),

      timeslot: map['confirmed_time']?.toString() ?? '',
      bookingdetails: map['requirements_booking']?.toString() ?? '',
      statusrequired: map['booking_status']?.toString() ?? 'Pending',

      startTime: parseDate(map['start_time']),
      endTime: parseDate(map['end_time']),

      duration: parseInt(map['duration']),
      serviceDuration: map['duration']?.toString(),
      servicePrice: rawPrice?.toString(),
      serviceOptionId: parseInt(map['service_option_id'] ?? map['service_id']),
      emailSent: map['email_sent'] == true,
      paymentStatus: map['payment_status']?.toString() ?? 'Pending',
      paymentMethod: map['payment_method']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    double? parsedPrice;
    if (servicePrice != null && servicePrice!.isNotEmpty) {
      final sanitized = servicePrice!.replaceAll(RegExp(r'[^0-9.]'), '');
      parsedPrice = double.tryParse(sanitized);
    }

    return {
      if (businessRef != null) "business_ref": businessRef,
      if (customerRef != null) "customer_id": customerRef,
      if (serviceRef != null) "service_id": serviceRef,
      if (therapistRef != null) "staff_id": therapistRef,
      "customer_ref": customer,
      "services": servicename,
      "therapist": therapistname,
      "available_slot": bookingdate.toIso8601String(),
      "confirmed_time": timeslot,
      "requirements_booking": bookingdetails,
      "booking_status": statusrequired,
      "payment_status": paymentStatus ?? 'unpaid',
      if (paymentMethod != null) "payment_method": paymentMethod,
      if (startTime != null) "start_time": startTime!.toIso8601String(),
      if (endTime != null) "end_time": endTime!.toIso8601String(),
      if (duration != null) "duration": duration,
      if (serviceOptionId != null) "service_option_id": serviceOptionId,
      "email_sent": emailSent,
      if (parsedPrice != null) "rate": parsedPrice,
      if (parsedPrice != null) "total_amount": parsedPrice,
      if (parsedPrice != null && paymentStatus?.toLowerCase() == 'paid')
        "paid_amount": parsedPrice,
    };
  }
}
