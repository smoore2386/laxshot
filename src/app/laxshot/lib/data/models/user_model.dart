import 'package:cloud_firestore/cloud_firestore.dart';

enum PlayerPosition { attacker, midfielder, defender, goalie }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final DateTime dateOfBirth;
  final PlayerPosition position;
  final bool isMinor;          // age < 13
  final bool parentApproved;   // COPPA consent granted
  final String? parentEmail;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.dateOfBirth,
    required this.position,
    required this.isMinor,
    required this.parentApproved,
    this.parentEmail,
    this.avatarUrl,
    required this.createdAt,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      position: PlayerPosition.values.firstWhere(
        (p) => p.name == data['position'],
        orElse: () => PlayerPosition.attacker,
      ),
      isMinor: data['isMinor'] as bool? ?? false,
      parentApproved: data['parentApproved'] as bool? ?? false,
      parentEmail: data['parentEmail'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'position': position.name,
        'isMinor': isMinor,
        'parentApproved': parentApproved,
        if (parentEmail != null) 'parentEmail': parentEmail,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? displayName,
    PlayerPosition? position,
    bool? parentApproved,
    String? parentEmail,
    String? avatarUrl,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        dateOfBirth: dateOfBirth,
        position: position ?? this.position,
        isMinor: isMinor,
        parentApproved: parentApproved ?? this.parentApproved,
        parentEmail: parentEmail ?? this.parentEmail,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
      );
}
