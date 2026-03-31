import 'package:uuid/uuid.dart';

// ==============================
// LOCATION
// ==============================
class LocationModel {
  String country;
  String city;
  double? latitude;
  double? longitude;

  LocationModel({
    this.country = "India",
    this.city = "",
    this.latitude,
    this.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
    country: json['country'] ?? "India",
    city: json['city'] ?? "",
    latitude: json['latitude'],
    longitude: json['longitude'],
  );

  Map<String, dynamic> toJson() => {
    'country': country,
    'city': city,
  };
}

// ==============================
// FAMILY MEMBER
// ==============================
class FamilyMemberModel {
  String memberId;
  String name;
  String relation;
  int? age;
  String profession;
  bool dependent;

  FamilyMemberModel({
    String? memberId,
    required this.name,
    required this.relation,
    this.age,
    this.profession = "",
    this.dependent = false,
  }) : memberId = memberId ?? const Uuid().v4();

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) =>
      FamilyMemberModel(
        memberId: json['member_id'],
        name: json['name'],
        relation: json['relation'],
        age: json['age'],
        profession: json['profession'] ?? "",
        dependent: json['dependent'] ?? false,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'member_id': memberId,
      'name': name,
      'relation': relation,
      'profession': profession,
      'dependent': dependent,
    };
    if (age != null) map['age'] = age;
    return map;
  }
}

// ==============================
// INCOME SOURCE
// ==============================
class IncomeSourceModel {
  String source;
  double amount;
  String frequency;
  List<String> ownerIds;
  bool isActive;

  IncomeSourceModel({
    required this.source,
    required this.amount,
    this.frequency = "monthly",
    required this.ownerIds,
    this.isActive = true,
  });

  factory IncomeSourceModel.fromJson(Map<String, dynamic> json) =>
      IncomeSourceModel(
        source: json['source'] ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        frequency: json['frequency'] ?? "monthly",
        ownerIds: List<String>.from(json['owner_ids'] ?? []),
        isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
    'source': source,
    'amount': amount,
    'frequency': frequency,
    'owner_ids': ownerIds,
    'is_active': isActive,
    'owner': ownerIds.isNotEmpty ? ownerIds.first : "self",
  };
}

class FinancialBalanceModel {
  double cashInBank;
  double totalAssets;
  double totalLiabilities;

  FinancialBalanceModel({
    this.cashInBank = 0,
    this.totalAssets = 0,
    this.totalLiabilities = 0,
  });
}

// ==============================
// USER MODEL (Root)
// ==============================
class UserModel {
  String userId;
  String email;
  String name;
  String phone;
  String profession;
  LocationModel location;
  String familyType;
  List<FamilyMemberModel> members;
  List<IncomeSourceModel> incomeSources;
  bool onboardingCompleted;
  DateTime? createdAt;

  // 🔥 NEW: language field (english or tamil)
  String language;

  UserModel({
    required this.userId,
    required this.email,
    required this.name,
    this.phone = "",
    this.profession = "",
    LocationModel? location,
    this.familyType = "individual",
    required this.members,
    required this.incomeSources,
    this.onboardingCompleted = false,
    this.createdAt,
    this.language = "english", // 🔥 default to english
  }) : location = location ?? LocationModel();

  int get membersCount => members.length;

  String get selfMemberId {
    return members
        .firstWhere(
          (m) => m.relation == 'self',
      orElse: () => FamilyMemberModel(name: name, relation: 'self'),
    )
        .memberId;
  }

  double get totalMonthlyIncome {
    return incomeSources
        .where((element) => element.frequency == 'monthly' && element.isActive)
        .fold(0, (sum, item) => sum + item.amount);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var membersList = json['members'] as List? ?? [];
    var incomeList = json['income_sources'] as List? ?? [];

    return UserModel(
      userId: json['user_id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'] ?? "",
      profession: json['profession'] ?? "",
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : LocationModel(),
      familyType: json['family_type'] ?? "individual",
      members: membersList.map((e) => FamilyMemberModel.fromJson(e)).toList(),
      incomeSources:
      incomeList.map((e) => IncomeSourceModel.fromJson(e)).toList(),
      onboardingCompleted: json['onboarding_completed'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      language: json['language'] ?? "english", // 🔥 read from backend
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'email': email,
    'name': name,
    'phone': phone,
    'profession': profession,
    'location': location.toJson(),
    'family_type': familyType,
    'members': members.map((e) => e.toJson()).toList(),
    'income_sources': incomeSources.map((e) => e.toJson()).toList(),
    'onboarding_completed': onboardingCompleted,
    'savings': [],
    'assets': [],
    'liabilities': [],
    'language': language, // 🔥 now uses the actual field, not hardcoded 'english'
    'currency': 'INR',
    'auth_provider': 'email',
    'monthly_income': totalMonthlyIncome,
    'monthly_savings': 0.0,
    'financial_behavior': {},
  };
}