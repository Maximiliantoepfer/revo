import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      // Ensure ID is not null or empty
      final id = json['id'] as String? ?? '';
      if (id.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      
      // Ensure username is not null or empty
      String username = json['username'] as String? ?? 'User';
      if (username.isEmpty) {
        username = 'User';
      }
      
      // Ensure email is not null or empty
      final email = json['email'] as String? ?? '';
      if (email.isEmpty) {
        throw Exception('User email cannot be empty');
      }
      
      // Handle createdAt with various formats
      DateTime createdAt;
      final createdAtData = json['createdAt'];
      if (createdAtData is Timestamp) {
        createdAt = createdAtData.toDate();
      } else if (createdAtData is String) {
        try {
          createdAt = DateTime.parse(createdAtData);
        } catch (_) {
          createdAt = DateTime.now();
        }
      } else {
        createdAt = DateTime.now();
      }
      
      return User(
        id: id,
        username: username,
        email: email,
        photoUrl: json['photoUrl'] as String?,
        createdAt: createdAt,
      );
    } catch (e) {
      print('Error parsing user data: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}