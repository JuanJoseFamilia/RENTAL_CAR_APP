// lib/models/conversation_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String reservationId;
  final String vehicleId;
  final String userId;
  final String? adminId;
  final String? lastMessage;
  final String? welcomeMessage;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.reservationId,
    required this.vehicleId,
    required this.userId,
    this.adminId,
    this.lastMessage,
    this.welcomeMessage,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reservationId': reservationId,
      'vehicleId': vehicleId,
      'userId': userId,
      'adminId': adminId,
      'lastMessage': lastMessage,
      'welcomeMessage': welcomeMessage,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map, String id) {
    return ConversationModel(
      id: id,
      reservationId: map['reservationId'] as String,
      vehicleId: map['vehicleId'] as String,
      userId: map['userId'] as String,
      adminId: map['adminId'] as String?,
      lastMessage: map['lastMessage'] as String?,
      welcomeMessage: map['welcomeMessage'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}
