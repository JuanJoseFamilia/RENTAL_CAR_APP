const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

/**
 * Trigger: on reservation create
 * - Creates a conversation linked to the reservation if none exists
 * - Adds an initial admin message to the conversation
 */
exports.onReservationCreate = functions.firestore
  .document('reservations/{reservationId}')
  .onCreate(async (snap, context) => {
    try {
      const reservation = snap.data();
      const reservationId = context.params.reservationId;
      if (!reservation) return null;

      const userId = reservation.userId;
      const vehicleId = reservation.vehicleId;

      // Check for existing conversation for this reservation
      const convQuery = await db
        .collection('conversations')
        .where('reservationId', '==', reservationId)
        .limit(1)
        .get();

      let convRef;

      // Try to find an admin user in `users` collection to set adminId
      let adminId = null;
      try {
        const adminQuery = await db
          .collection('users')
          .where('role', '==', 'admin')
          .limit(1)
          .get();
        if (!adminQuery.empty) {
          adminId = adminQuery.docs[0].id;
        }
      } catch (err) {
        console.warn('No se pudo buscar admin en users:', err);
      }

      if (!convQuery.empty) {
        convRef = convQuery.docs[0].ref;
      } else {
        // Create conversation
        convRef = await db.collection('conversations').add({
          reservationId: reservationId,
          vehicleId: vehicleId || null,
          userId: userId || null,
          adminId: adminId,
          lastMessage: 'Procesando reserva...',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // NOTE: Mensaje de voucher ahora es enviado por la app Flutter en reservation_service.dart
      // para asegurar que tenga toda la información completa del vehículo y usuario
      // La Cloud Function solo crea la conversación
      
      console.log('Conversation created for reservation:', reservationId);
      return null;
    } catch (error) {
      console.error('Error in onReservationCreate:', error);
      return null;
    }
  });
