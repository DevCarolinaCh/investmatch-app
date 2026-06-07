// Modelos de usuario para inversores y emprendedores

enum UserRole { investor, founder, admin, moderator }

enum KycStatus { pending, inProgress, verified, rejected }

enum SubscriptionPlan { free, pro, enterprise }

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final UserRole role;
  final KycStatus kycStatus;
  final SubscriptionPlan plan;
  final String? province;
  final String? bio;
  final String? linkedinUrl;
  final bool isActive;
  final DateTime createdAt;

  // Solo para inversores
  final InvestorProfile? investorProfile;

  // Solo para emprendedores
  final FounderProfile? founderProfile;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.kycStatus,
    required this.plan,
    this.province,
    this.bio,
    this.linkedinUrl,
    required this.isActive,
    required this.createdAt,
    this.investorProfile,
    this.founderProfile,
  });

  bool get isVerified => kycStatus == KycStatus.verified;
  bool get isInvestor => role == UserRole.investor;
  bool get isFounder => role == UserRole.founder;
  bool get isPro => plan == SubscriptionPlan.pro || plan == SubscriptionPlan.enterprise;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: UserRole.values.byName(json['role'] as String),
      kycStatus: KycStatus.values.byName(json['kycStatus'] as String),
      plan: SubscriptionPlan.values.byName(json['plan'] as String),
      province: json['province'] as String?,
      bio: json['bio'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      investorProfile: json['investorProfile'] != null
          ? InvestorProfile.fromJson(json['investorProfile'] as Map<String, dynamic>)
          : null,
      founderProfile: json['founderProfile'] != null
          ? FounderProfile.fromJson(json['founderProfile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'role': role.name,
        'kycStatus': kycStatus.name,
        'plan': plan.name,
        'province': province,
        'bio': bio,
        'linkedinUrl': linkedinUrl,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'investorProfile': investorProfile?.toJson(),
        'founderProfile': founderProfile?.toJson(),
      };

  UserModel copyWith({
    String? email,
    String? fullName,
    String? avatarUrl,
    KycStatus? kycStatus,
    SubscriptionPlan? plan,
    String? province,
    String? bio,
    String? linkedinUrl,
    InvestorProfile? investorProfile,
    FounderProfile? founderProfile,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role,
      kycStatus: kycStatus ?? this.kycStatus,
      plan: plan ?? this.plan,
      province: province ?? this.province,
      bio: bio ?? this.bio,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      isActive: isActive,
      createdAt: createdAt,
      investorProfile: investorProfile ?? this.investorProfile,
      founderProfile: founderProfile ?? this.founderProfile,
    );
  }
}

class InvestorProfile {
  final String userId;
  final List<String> preferredVerticals;
  final List<String> preferredStages;
  final String preferredTicketRange;
  final List<String> preferredProvinces;
  final List<String> impactFocus;
  final String? fundName;
  final bool isAngelInvestor;
  final int totalInvestments;
  final double? portfolioSize;

  const InvestorProfile({
    required this.userId,
    required this.preferredVerticals,
    required this.preferredStages,
    required this.preferredTicketRange,
    required this.preferredProvinces,
    required this.impactFocus,
    this.fundName,
    required this.isAngelInvestor,
    required this.totalInvestments,
    this.portfolioSize,
  });

  factory InvestorProfile.fromJson(Map<String, dynamic> json) {
    return InvestorProfile(
      userId: json['userId'] as String,
      preferredVerticals: List<String>.from(json['preferredVerticals'] as List),
      preferredStages: List<String>.from(json['preferredStages'] as List),
      preferredTicketRange: json['preferredTicketRange'] as String,
      preferredProvinces: List<String>.from(json['preferredProvinces'] as List),
      impactFocus: List<String>.from(json['impactFocus'] as List),
      fundName: json['fundName'] as String?,
      isAngelInvestor: json['isAngelInvestor'] as bool,
      totalInvestments: json['totalInvestments'] as int,
      portfolioSize: (json['portfolioSize'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'preferredVerticals': preferredVerticals,
        'preferredStages': preferredStages,
        'preferredTicketRange': preferredTicketRange,
        'preferredProvinces': preferredProvinces,
        'impactFocus': impactFocus,
        'fundName': fundName,
        'isAngelInvestor': isAngelInvestor,
        'totalInvestments': totalInvestments,
        'portfolioSize': portfolioSize,
      };
}

class FounderProfile {
  final String userId;
  final String companyName;
  final String vertical;
  final String stage;
  final String ticketSeeking;
  final String province;
  final List<String> impactFocus;
  final String? websiteUrl;
  final String? pitchDeckUrl;
  final double? mrr;
  final int? teamSize;
  final int? foundedYear;

  const FounderProfile({
    required this.userId,
    required this.companyName,
    required this.vertical,
    required this.stage,
    required this.ticketSeeking,
    required this.province,
    required this.impactFocus,
    this.websiteUrl,
    this.pitchDeckUrl,
    this.mrr,
    this.teamSize,
    this.foundedYear,
  });

  factory FounderProfile.fromJson(Map<String, dynamic> json) {
    return FounderProfile(
      userId: json['userId'] as String,
      companyName: json['companyName'] as String,
      vertical: json['vertical'] as String,
      stage: json['stage'] as String,
      ticketSeeking: json['ticketSeeking'] as String,
      province: json['province'] as String,
      impactFocus: List<String>.from(json['impactFocus'] as List),
      websiteUrl: json['websiteUrl'] as String?,
      pitchDeckUrl: json['pitchDeckUrl'] as String?,
      mrr: (json['mrr'] as num?)?.toDouble(),
      teamSize: json['teamSize'] as int?,
      foundedYear: json['foundedYear'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'companyName': companyName,
        'vertical': vertical,
        'stage': stage,
        'ticketSeeking': ticketSeeking,
        'province': province,
        'impactFocus': impactFocus,
        'websiteUrl': websiteUrl,
        'pitchDeckUrl': pitchDeckUrl,
        'mrr': mrr,
        'teamSize': teamSize,
        'foundedYear': foundedYear,
      };
}
