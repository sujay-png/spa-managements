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
    return ClientModel(
      id: map['id'] as int?,
      businessRef: map['business_ref'] ,
      date: map['date'] ?? '',
      time: '', // Note: DB uses appointment_datetime or date
      name: map['customer_name'] ?? map['name'] ?? '',
    phone: map['customer_phone'] ?? map['phone'] ?? '',
    email: map['customer_email'] ?? map['email'] ?? '',
    location: map['customer_address'] ?? map['location'] ?? '',
    
      age: map['age']?.toString() ?? '',
  
      loyaltyCardNo: map['loyalty_card_no'] ?? '',
      customerId: map['customer_id'] as int?,
      signatureUrl: map['signature_url'] as String?,
      dob: map['dob'] as String?,
      status: map['status'] as String?,
      therapistId: map['therapist_id'] as int?,
      appointmentDatetime: map['appointment_datetime'] as String?,
      massageGoal: map['massage_goal'] as String?,
      bodyFocusArea: map['body_focus_area'] as String?,
      skinAllergy: map['skin_allergy'] as String?,
      isPregnant: map['is_pregnant'] as String?,
      cardiacProblems: map['cardiac_problems'] as String?,
      recentSurgery: map['recent_surgery'] as String?,
      lifestyleType: map['lifestyle_type'] as String?,
      sessionFrequency: map['session_frequency'] as String?,
      serviceName: map['service_name'] as String?,
serviceTime: map['time'] as String?,
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