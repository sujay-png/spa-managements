class ClientModel {
  final int? id;

  // ── Basic Details ──────────────────────────────────────────
  final String date;
  final String time;
  final String name;
  final String age;
  final String email;
  final String phone;
  final String location;
  final String loyaltyCardNo;

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

  ClientModel({
    this.id,
    required this.date,
    required this.time,
    required this.name,
    required this.age,
    required this.email,
    required this.phone,
    required this.location,
    required this.loyaltyCardNo,
    this.massageGoal,
    this.bodyFocusArea,
    this.skinAllergy,
    this.isPregnant,
    this.cardiacProblems,
    this.recentSurgery,
    this.lifestyleType,
    this.sessionFrequency,
  });

  // ✅ FIXED MAPPING
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,

    // 🔥 IMPORTANT: Match DB column names
    'customer_name': name,
    'customer_phone': phone,
    'customer_email': email,
    'customer_address': location,

    // Optional fields
    'date': date,
    'time': time,
    'age': age,
    'loyalty_card_no': loyaltyCardNo,

    'massage_goal': massageGoal,
    'body_focus_area': bodyFocusArea,
    'skin_allergy': skinAllergy,
    'is_pregnant': isPregnant,
    'cardiac_problems': cardiacProblems,
    'recent_surgery': recentSurgery,
    'lifestyle_type': lifestyleType,
    'session_frequency': sessionFrequency,
  };

  // ✅ FIXED FROM MAP
  factory ClientModel.fromMap(Map<String, dynamic> map) => ClientModel(
    id: map['id'] as int?,
    date: map['date'] ?? '',
    time: map['time'] ?? '',
    name: map['customer_name'] ?? '',
    age: map['age'] ?? '',
    email: map['customer_email'] ?? '',
    phone: map['customer_phone'] ?? '',
    location: map['customer_address'] ?? '',
    loyaltyCardNo: map['loyalty_card_no'] ?? '',
    massageGoal: map['massage_goal'],
    bodyFocusArea: map['body_focus_area'],
    skinAllergy: map['skin_allergy'],
    isPregnant: map['is_pregnant'],
    cardiacProblems: map['cardiac_problems'],
    recentSurgery: map['recent_surgery'],
    lifestyleType: map['lifestyle_type'],
    sessionFrequency: map['session_frequency'],
  );
}
