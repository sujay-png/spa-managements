class ClientModel {
  final int? id;
    int? businessRef;

  // ── Basic Details ──────────────────────────────────────────
  final String date;
  final String time;
  final String name;
  final String age;
  final String email;
  final String phone;
  final String location;
  final String loyaltyCardNo;
  final int? customerId;
  final String? signatureUrl;
  final String? dob;
  final String? status;
  final int? therapistId;
  final String? appointmentDatetime;

  // ── Goals & Concerns ──────────────────────────────────────
  final String? massageGoal;
  final String? bodyFocusArea;

  // ── Health History ────────────────────────────────────────
  final String? skinAllergy;
  final String? isPregnant;
  final String? cardiacProblems;
  final String? recentSurgery;

  // ── Lifestyle ─────────────────────────────────────────────
  final String? lifestyleType;
  final String? sessionFrequency;
  final String? serviceName;
final String? serviceTime;

  ClientModel({
    this.id,
    this.businessRef,
    required this.date,
    this.time = '',
    required this.name,
    required this.age,
    required this.email,
    required this.phone,
    required this.location,
    required this.loyaltyCardNo,
    this.customerId,
    this.signatureUrl,
    this.dob,
    this.status,
    this.therapistId,
    this.appointmentDatetime,
    this.massageGoal,
    this.bodyFocusArea,
    this.skinAllergy,
    this.isPregnant,
    this.cardiacProblems,
    this.recentSurgery,
    this.lifestyleType,
    this.sessionFrequency,
    this.serviceName,
    this.serviceTime,
  });

  // ── Mapped to DB Schema: public.clients ───────────────────
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'business_ref': businessRef,
        'date': date,
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'loyalty_card_no': loyaltyCardNo,
        'age': age,
        'customer_id': customerId,
        'signature_url': signatureUrl,
        'dob': dob,
        if (status != null) 'status': status,
        'therapist_id': therapistId,
        'appointment_datetime': appointmentDatetime,
        'massage_goal': massageGoal,
        'body_focus_area': bodyFocusArea,
        'skin_allergy': skinAllergy,
        'is_pregnant': isPregnant,
        'cardiac_problems': cardiacProblems,
        'recent_surgery': recentSurgery,
        'lifestyle_type': lifestyleType,
        'session_frequency': sessionFrequency,
        'service_name': serviceName,
  'time': serviceTime,
      };

  // ── Mapped from DB Schema: public.clients ─────────────────
  factory ClientModel.fromMap(Map<String, dynamic> map) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return ClientModel(
      id: parseInt(map['id']),
      businessRef: parseInt(map['business_ref']),
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      name: map['customer_name']?.toString() ?? map['name']?.toString() ?? '',
      phone: map['customer_phone']?.toString() ??
          map['phone']?.toString() ??
          '',
      email: map['customer_email']?.toString() ?? map['email']?.toString() ?? '',
      location: map['customer_address']?.toString() ??
          map['location']?.toString() ??
          '',
      age: map['age']?.toString() ?? '',
      loyaltyCardNo: map['loyalty_card_no']?.toString() ?? '',
      customerId: parseInt(map['customer_id']),
      signatureUrl: map['signature_url']?.toString(),
      dob: map['dob']?.toString(),
      status: map['status']?.toString(),
      therapistId: parseInt(map['therapist_id']),
      appointmentDatetime: map['appointment_datetime']?.toString(),
      massageGoal: map['massage_goal']?.toString(),
      bodyFocusArea: map['body_focus_area']?.toString(),
      skinAllergy: map['skin_allergy']?.toString(),
      isPregnant: map['is_pregnant']?.toString(),
      cardiacProblems: map['cardiac_problems']?.toString(),
      recentSurgery: map['recent_surgery']?.toString(),
      lifestyleType: map['lifestyle_type']?.toString(),
      sessionFrequency: map['session_frequency']?.toString(),
      serviceName: map['service_name']?.toString(),
      serviceTime: map['time']?.toString() ?? map['duration']?.toString(),
    );
  }

 @override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is ClientModel &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        phone == other.phone;

@override
int get hashCode => id.hashCode ^ phone.hashCode;
}