// lib/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderRole; // 'user' or 'admin'
  final String text;
  final DateTime createdAt;
  final String? attachmentUrl;
  final List<String> readBy;
  final List<String> deliveredTo;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.attachmentUrl,
    List<String>? readBy,
      List<String>? deliveredTo,
    }) : readBy = readBy ?? [], deliveredTo = deliveredTo ?? [];

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachmentUrl': attachmentUrl,
      'readBy': readBy,
      'deliveredTo': deliveredTo,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle createdAt safely - use current time if null
    DateTime createdAt = DateTime.now();
    if (map['createdAt'] != null && map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    }

    return MessageModel(
      id: id,
      senderId: map['senderId'] as String,
      senderRole: map['senderRole'] as String,
      text: map['text'] as String,
      createdAt: createdAt,
      attachmentUrl: map['attachmentUrl'] as String?,
      readBy: List<String>.from(map['readBy'] ?? []),
      deliveredTo: List<String>.from(map['deliveredTo'] ?? []),
    );
  }
}
