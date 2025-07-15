import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { investor, entrepreneur }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final bool isApproved;
  final String? profilePicture;
  final String? bio;
  final CompanyInfo? company;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isApproved,
    this.profilePicture,
    this.bio,
    this.company,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] == 'investor'
          ? UserRole.investor
          : UserRole.entrepreneur,
      isApproved: data['isApproved'] ?? false,
      profilePicture: data['profilePicture'],
      bio: data['bio'],
      company:
          data['company'] != null ? CompanyInfo.fromMap(data['company']) : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role == UserRole.investor ? 'investor' : 'entrepreneur',
      'isApproved': isApproved,
      'profilePicture': profilePicture,
      'bio': bio,
      'company': company?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    bool? isApproved,
    String? profilePicture,
    String? bio,
    CompanyInfo? company,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      company: company ?? this.company,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CompanyInfo {
  final String name;
  final String sector;
  final String? website;
  final int? foundedYear;

  CompanyInfo({
    required this.name,
    required this.sector,
    this.website,
    this.foundedYear,
  });

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      name: map['name'] ?? '',
      sector: map['sector'] ?? '',
      website: map['website'],
      foundedYear: map['foundedYear'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sector': sector,
      'website': website,
      'foundedYear': foundedYear,
    };
  }
}
