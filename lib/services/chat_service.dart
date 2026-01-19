// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _conversationsColl = 'conversations';

  Future<String> ensureConversation({
    required String reservationId,
    required String vehicleId,
    required String userId,
    String? welcomeMessage,
  }) async {
    try {
      final q = await _firestore
          .collection(_conversationsColl)
          .where('reservationId', isEqualTo: reservationId)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) return q.docs.first.id;

      final docRef = await _firestore.collection(_conversationsColl).add({
        'reservationId': reservationId,
        'vehicleId': vehicleId,
        'userId': userId,
        'adminId': null,
        'lastMessage': welcomeMessage,
        'welcomeMessage': welcomeMessage,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      });

      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('No tiene permiso para acceder o crear la conversación: ${e.message}');
    }
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _firestore
        .collection(_conversationsColl)
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String text,
    String? attachmentUrl,
  }) async {
    try {
      final messagesRef = _firestore
          .collection(_conversationsColl)
          .doc(conversationId)
          .collection('messages');

      final messageData = {
        'senderId': senderId,
        'senderRole': senderRole,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'attachmentUrl': attachmentUrl,
        'readBy': <String>[senderId], // sender has seen their message - typed array
        'deliveredTo': <String>[senderId], // sender device considered delivered
      };

      final docRef = await messagesRef.add(messageData);
      if (kDebugMode) print('📤 Mensaje enviado: ${docRef.id}');

      // Update conversation metadata
      await _firestore.collection(_conversationsColl).doc(conversationId).update({
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (kDebugMode) print('❌ Error enviando mensaje: ${e.message}');
      throw Exception('No tiene permiso para enviar mensajes o hubo un error: ${e.message}');
    }
  }

  Future<void> markMessageRead({
    required String conversationId,
    required String messageId,
    required String userId,
  }) async {
    try {
      final msgRef = _firestore
          .collection(_conversationsColl)
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);

      // Primero verificar si el mensaje existe
      final docSnapshot = await msgRef.get();
      if (!docSnapshot.exists) {
        if (kDebugMode) print('Mensaje no encontrado: $messageId');
        return;
      }

      // Obtener el readBy actual
      final currentReadBy = List<String>.from(docSnapshot.get('readBy') ?? []);
      
      // Si el usuario ya está en readBy, no hacer nada
      if (currentReadBy.contains(userId)) {
        if (kDebugMode) print('Mensaje ya estaba marcado como leído para $userId');
        return;
      }

      // Agregar el usuario a readBy
      currentReadBy.add(userId);
      
      await msgRef.update({
        'readBy': currentReadBy,
      });
      
      if (kDebugMode) print('✅ Mensaje $messageId marcado como leído por $userId');
    } catch (e) {
      if (kDebugMode) print('❌ Error al marcar mensaje como leído: $e');
      rethrow;
    }
  }

  // Mark message as delivered (device has received it)
  Future<void> markMessageDelivered({
    required String conversationId,
    required String messageId,
    required String userId,
  }) async {
    try {
      final msgRef = _firestore
          .collection(_conversationsColl)
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);

      final docSnapshot = await msgRef.get();
      if (!docSnapshot.exists) {
        if (kDebugMode) print('Mensaje no encontrado (deliver): $messageId');
        return;
      }

      final currentDelivered = List<String>.from(docSnapshot.get('deliveredTo') ?? []);
      if (currentDelivered.contains(userId)) return;
      currentDelivered.add(userId);

      await msgRef.update({
        'deliveredTo': currentDelivered,
      });

      if (kDebugMode) print('📥 Mensaje $messageId entregado a $userId');
    } catch (e) {
      if (kDebugMode) print('❌ Error al marcar mensaje como entregado: $e');
      rethrow;
    }
  }

  // Mark all messages in a conversation as read
  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      if (kDebugMode) print('📌 Iniciando marcado de conversación $conversationId como leída para $userId');
      
      final messageSnap = await _firestore
          .collection(_conversationsColl)
          .doc(conversationId)
          .collection('messages')
          .get();

      int markedCount = 0;
      
      for (var msgDoc in messageSnap.docs) {
        final readBy = List<String>.from(msgDoc.get('readBy') ?? []);
        if (!readBy.contains(userId)) {
          readBy.add(userId);
          await msgDoc.reference.update({
            'readBy': readBy,
          });
          markedCount++;
        }
      }

      // Reset unreadCount to 0
      await _firestore
          .collection(_conversationsColl)
          .doc(conversationId)
          .update({'unreadCount': 0});
          
      if (kDebugMode) print('✅ Conversación marcada como leída: $markedCount mensajes actualizados');
    } catch (e) {
      if (kDebugMode) print('❌ Error al marcar conversación como leída: $e');
      rethrow;
    }
  }

  Stream<List<ConversationModel>> streamUserConversations(String userId) {
    return _firestore
        .collection(_conversationsColl)
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ConversationModel.fromMap(d.data(), d.id))
            .toList());
  }

  // Stream all conversations (for admin view)
  Stream<List<ConversationModel>> streamAllConversations() {
    return _firestore
        .collection(_conversationsColl)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ConversationModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<ConversationModel?> getConversationById(String id) async {
    final doc = await _firestore.collection(_conversationsColl).doc(id).get();
    if (!doc.exists) return null;
    return ConversationModel.fromMap(doc.data()!, doc.id);
  }

  // Get count of unread messages in a specific conversation
  Future<int> getUnreadCountForConversation(String conversationId, String userId) async {
    try {
      final messageSnap = await _firestore
          .collection(_conversationsColl)
          .doc(conversationId)
          .collection('messages')
          .get();

      int unreadCount = 0;
      for (var msgDoc in messageSnap.docs) {
        final readBy = List<String>.from(msgDoc.get('readBy') ?? []);
        if (!readBy.contains(userId)) {
          unreadCount++;
        }
      }
      return unreadCount;
    } catch (e) {
      return 0;
    }
  }

  // Stream count of unread messages for a specific conversation
  Stream<int> streamUnreadCountForConversation(String conversationId, String userId) {
    return _firestore
        .collection(_conversationsColl)
        .doc(conversationId)
        .collection('messages')
        .snapshots()
        .map((messageSnap) {
          int unreadCount = 0;
          for (var msgDoc in messageSnap.docs) {
            final readBy = List<String>.from(msgDoc.get('readBy') ?? []);
            if (!readBy.contains(userId)) {
              unreadCount++;
            }
          }
          return unreadCount;
        });
  }

  // Stream count of unread messages across all user conversations
  Stream<int> streamUnreadMessageCount(String userId) {
    return _firestore
        .collection(_conversationsColl)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((conversationSnap) async {
          int totalUnread = 0;
          
          for (var convDoc in conversationSnap.docs) {
            final messageSnap = await _firestore
                .collection(_conversationsColl)
                .doc(convDoc.id)
                .collection('messages')
                .get();
            
            for (var msgDoc in messageSnap.docs) {
              final readBy = List<String>.from(msgDoc.get('readBy') ?? []);
              if (!readBy.contains(userId)) {
                totalUnread++;
              }
            }
          }
          
          return totalUnread;
        });
  }

  // Stream count of unread messages across all conversations for admin
  Stream<int> streamUnreadMessageCountForAdmin() {
    return _firestore
        .collection(_conversationsColl)
        .snapshots()
        .asyncMap((conversationSnap) async {
          int totalUnread = 0;
          
          for (var convDoc in conversationSnap.docs) {
            final messageSnap = await _firestore
                .collection(_conversationsColl)
                .doc(convDoc.id)
                .collection('messages')
                .get();
            
            for (var msgDoc in messageSnap.docs) {
              final readBy = List<String>.from(msgDoc.get('readBy') ?? []);
              final senderId = msgDoc.get('senderId') ?? '';
              // Count messages that are NOT from admin and admin hasn't read
              // This prevents counting admin's own messages
              if (senderId != 'admin' && !readBy.contains('admin')) {
                totalUnread++;
              }
            }
          }
          
          return totalUnread;
        });
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
    // Format dates
    final startDateStr = _formatDate(startDate);
    final endDateStr = _formatDate(endDate);
    final startTime = _formatTime(startDate);
    final endTime = _formatTime(endDate);

    // Format price with currency
    final priceStr = totalPrice.toStringAsFixed(2);

    // Format status
    final statusFormatted = status.isEmpty ? 'Pendiente' : status[0].toUpperCase() + status.substring(1);

    return '''
════════════════════════════════════════════
         DETALLES DE TU RESERVA
════════════════════════════════════════════

👤 CLIENTE: $clientName
📋 ID RESERVA: $reservationId

🚗 VEHÍCULO: $vehicleName

📅 FECHA DE INICIO: $startDateStr
   ⏰ Hora: $startTime

📅 FECHA DE FIN: $endDateStr
   ⏰ Hora: $endTime

⏱️  DURACIÓN: $days día(s)

💰 PRECIO TOTAL: \$$priceStr

📊 ESTADO: $statusFormatted

════════════════════════════════════════════

Hola $clientName! 👋

Gracias por tu confianza. Esta es la información de tu reserva. Si tienes alguna pregunta sobre el vehículo, las condiciones de alquiler, o cualquier otro detalle, responde aquí y te ayudaré con gusto.

¡Estamos aquí para asegurarnos de que tengas la mejor experiencia!

════════════════════════════════════════════''';
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  // Helper method to format time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
