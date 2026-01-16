// lib/providers/chat_provider.dart
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  // Create or get an existing conversation
  Future<String> ensureConversation({
    required String reservationId,
    required String vehicleId,
    required String userId,
    String? welcomeMessage,
  }) async {
    return await _chatService.ensureConversation(
      reservationId: reservationId,
      vehicleId: vehicleId,
      userId: userId,
      welcomeMessage: welcomeMessage,
    );
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _chatService.streamMessages(conversationId);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String text,
    String? attachmentUrl,
  }) async {
    await _chatService.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderRole: senderRole,
      text: text,
      attachmentUrl: attachmentUrl,
    );
  }

  Future<void> markMessageRead({
    required String conversationId,
    required String messageId,
    required String userId,
  }) async {
    await _chatService.markMessageRead(
      conversationId: conversationId,
      messageId: messageId,
      userId: userId,
    );
  }

  // Mark entire conversation as read
  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    await _chatService.markConversationAsRead(
      conversationId: conversationId,
      userId: userId,
    );
  }

  // Stream de conversaciones del usuario
  Stream<List<ConversationModel>> streamUserConversations(String userId) {
    return _chatService.streamUserConversations(userId);
  }

  // Stream para que el admin vea todas las conversaciones
  Stream<List<ConversationModel>> streamAllConversations() {
    return _chatService.streamAllConversations();
  }

  Future<ConversationModel?> getConversationById(String id) async {
    return await _chatService.getConversationById(id);
  }

  Future<int> getUnreadCountForConversation(String conversationId, String userId) async {
    return await _chatService.getUnreadCountForConversation(conversationId, userId);
  }

  // Stream unread count for a specific conversation
  Stream<int> streamUnreadCountForConversation(String conversationId, String userId) {
    return _chatService.streamUnreadCountForConversation(conversationId, userId);
  }

  Stream<int> streamUnreadMessageCount(String userId) {
    return _chatService.streamUnreadMessageCount(userId);
  }

  // Stream unread message count for admin (all conversations)
  Stream<int> streamUnreadMessageCountForAdmin() {
    return _chatService.streamUnreadMessageCountForAdmin();
  }

  // Generate a detailed reservation voucher message
  String generateReservationVoucher({
    required String reservationId,
    required String clientName,
    required String vehicleName,
    required DateTime startDate,
    required DateTime endDate,
    required int days,
    required double totalPrice,
    required String status,
  }) {
    return _chatService.generateReservationVoucher(
      reservationId: reservationId,
      clientName: clientName,
      vehicleName: vehicleName,
      startDate: startDate,
      endDate: endDate,
      days: days,
      totalPrice: totalPrice,
      status: status,
    );
  }
}
