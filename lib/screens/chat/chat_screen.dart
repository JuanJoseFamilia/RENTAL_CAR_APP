import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/message_model.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../../services/reservation_service.dart';
import '../../models/reservation_model.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String? reservationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.reservationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;
  bool _loading = true;
  Future<ReservationModel?>? _reservationFuture;
  
  // Local cache para mensajes sin parpadeos
  final ValueNotifier<List<MessageModel>> _messagesNotifier = ValueNotifier([]);
  final Set<String> _markedAsRead = {};
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _markConversationAsRead();
    _initializeMessages();
  }

  // Mark entire conversation as read when opening
  Future<void> _markConversationAsRead() async {
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;
    
    if (currentUserId != null) {
      // Always use the real authenticated UID, never 'admin' string
      // This ensures Firestore security rules validate correctly
      await chatProvider.markConversationAsRead(
        conversationId: widget.conversationId,
        userId: currentUserId,
      );
    }
  }

  Future<void> _initializeMessages() async {
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;

    try {
      // First load to check if conversation is empty
      final initialMessages = await chatProvider.streamMessages(widget.conversationId).first;
      
      // If conversation is empty, send the detailed voucher
      if (initialMessages.isEmpty && widget.reservationId != null) {
        await _sendDetailedVoucher();
      }

      // Cargar mensajes continuamente
      _messageSubscription = chatProvider.streamMessages(widget.conversationId).listen((messages) async {
        // Actualizar el cache sin reconstruir el widget
        _messagesNotifier.value = messages;

        // Marcar como entregado (delivered) y/o leído (seen)
        if (currentUserId != null) {
          for (var m in messages) {
            // If this device is not the sender, acknowledge delivery
            if (m.senderId != currentUserId) {
              try {
                if (!m.deliveredTo.contains(currentUserId)) {
                  await chatProvider.markMessageDelivered(
                    conversationId: widget.conversationId,
                    messageId: m.id,
                    userId: currentUserId,
                  );
                }
              } catch (e) {
                if (kDebugMode) print('Error marcando mensaje como entregado: $e');
              }
            }

            // Mark as read (seen) when the user has the conversation open
            if (!m.readBy.contains(currentUserId) && !_markedAsRead.contains(m.id)) {
              _markedAsRead.add(m.id);
              try {
                await chatProvider.markMessageRead(
                  conversationId: widget.conversationId,
                  messageId: m.id,
                  userId: currentUserId,
                );
              } catch (e) {
                if (kDebugMode) print('Error marcando mensaje como leído: $e');
              }
            }
          }
        }

        // Auto scroll suave
        if (_scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });

      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _sendDetailedVoucher() async {
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;

    if (currentUserId == null || widget.reservationId == null) return;

    try {
      // Get reservation data with all details
      final reservationService = ReservationService();
      final reservation = await reservationService.getReservationWithFullData(widget.reservationId!);
      
      if (reservation == null) return;

      // Build complete vehicle name with all available info
      final vehicleName = <String>[
        if (reservation.vehicleMarca != null && reservation.vehicleMarca!.isNotEmpty) reservation.vehicleMarca!,
        if (reservation.vehicleModelo != null && reservation.vehicleModelo!.isNotEmpty) reservation.vehicleModelo!,
      ].join(' ');

      // Generate voucher message with complete information
      final voucherText = chatProvider.generateReservationVoucher(
        reservationId: reservation.id,
        clientName: reservation.userName ?? reservation.userId,
        vehicleName: vehicleName.isNotEmpty ? vehicleName : 'Vehículo confirmado',
        startDate: reservation.fechaInicio,
        endDate: reservation.fechaFin,
        days: reservation.diasAlquiler,
        totalPrice: reservation.precioTotal,
        status: reservation.estado,
      );

      // Send as admin message
      await chatProvider.sendMessage(
        conversationId: widget.conversationId,
        senderId: 'admin',
        senderRole: 'admin',
        text: voucherText,
      );
    } catch (e) {
      // Silently fail - it's just a welcome message
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    _messagesNotifier.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.currentUser == null) return;

    final senderId = authProvider.currentUser!.id;
    final senderRole = authProvider.currentUser!.rol == 'admin' ? 'admin' : 'user';

    if (mounted) {
      setState(() => _sending = true);
      _controller.clear();
    }

    try {
      await chatProvider.sendMessage(
        conversationId: widget.conversationId,
        senderId: senderId,
        senderRole: senderRole,
        text: text,
      );
    } catch (e) {
      if (!mounted) return;
      
      _controller.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;

    // Init reservation future if not set
    _reservationFuture ??= () async {
      final reservationService = ReservationService();
      if (widget.reservationId != null) {
        return await reservationService.getReservationWithFullData(widget.reservationId!);
      }

      // Fallback: get conversation to read reservationId
      final chatProvider = context.read<ChatProvider>();
      final conv = await chatProvider.getConversationById(widget.conversationId);
      if (conv == null) return null;
      return await reservationService.getReservationWithFullData(conv.reservationId);
    }();

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<ReservationModel?>(
          future: _reservationFuture,
          builder: (context, snap) {
            final res = snap.data;
            final userName = res?.userName ?? res?.userId ?? 'Chat';
            final vehicleName = (res != null && res.vehicleMarca != null)
                ? '${res.vehicleMarca} ${res.vehicleModelo}'
                : 'Vehículo';
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      'Vehículo: ',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Expanded(
                      child: Text(
                        vehicleName,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListenableBuilder(
                    listenable: _messagesNotifier,
                    builder: (context, _) {
                      final messages = _messagesNotifier.value;

                      if (messages.isEmpty) {
                        return const Center(child: Text('Aún no hay mensajes'));
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final m = messages[index];
                          final isMine = m.senderId == currentUserId;
                          final isVoucher = m.text.contains('DETALLES DE TU RESERVA');

                          // Show voucher in special card format
                          if (isVoucher && m.senderRole == 'admin') {
                            return FutureBuilder<ReservationModel?>(
                              future: _reservationFuture,
                              builder: (context, snap) {
                                final reservation = snap.data;
                                return _buildVoucherCard(
                                  m,
                                  reservation,
                                );
                              },
                            );
                          }

                          // Show regular message

                          return Align(
                            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                                horizontal: AppSpacing.sm,
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              padding: EdgeInsets.all(
                                ResponsiveHelper.responsivePadding(
                                  context,
                                  AppSpacing.md,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: isMine ? AppColors.primary : AppColors.chatIncoming,
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                              ),
                              child: Column(
                                crossAxisAlignment: isMine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.text,
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: ResponsiveHelper.responsiveFontSize(
                                        context,
                                        AppFontSizes.sm,
                                      ),
                                    ),
                                    maxLines: null,
                                    overflow: TextOverflow.visible,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isMine) ...[
                                          Builder(builder: (context) {
                                            final hasDelivered = m.deliveredTo.any((id) => id != m.senderId);
                                            final hasSeen = m.readBy.any((id) => id != m.senderId);
                                            return Icon(
                                              (hasDelivered || hasSeen) ? Icons.done_all : Icons.done,
                                              size: 14,
                                              color: hasSeen ? Color(0xFF2E7D32) : AppColors.white,
                                            );
                                          }),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          _formatTime(m.createdAt),
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper
                                                .responsiveFontSize(
                                              context,
                                              AppFontSizes.xs,
                                            ),
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // no extra text for incoming messages; status shown via checks for sender
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(
                ResponsiveHelper.responsivePadding(context, AppSpacing.sm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _sending
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send),
                          color: AppColors.primary,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(MessageModel message, ReservationModel? reservation) {
    if (reservation == null) {
      // Show loading while reservation data is being fetched
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            color: AppColors.white,
          ),
          child: const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
      );
    }

    String formatDate(DateTime date) {
      const months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
      ];
      return '${date.day} de ${months[date.month - 1]}';
    }

    // Determinar color del borde según estado
    Color borderColor = AppColors.primary;
    if (reservation.estado == 'completada') {
      borderColor = AppColors.success;
    } else if (reservation.estado == 'cancelada') {
      borderColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        color: AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle image
          if (reservation.vehicleImagenUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              child: CachedNetworkImage(
                imageUrl: reservation.vehicleImagenUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180,
                  width: double.infinity,
                  color: AppColors.grey,
                  child: const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  width: double.infinity,
                  color: AppColors.grey,
                  child: const Icon(Icons.directions_car, size: 60),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          // Title
          const Text(
            'Detalles de tu Reserva',
            style: TextStyle(
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Vehicle
          _buildVoucherInfoRow('Vehículo', reservation.vehicleNombre),
          const SizedBox(height: AppSpacing.sm),

          // Client
          _buildVoucherInfoRow('Cliente', reservation.userName ?? reservation.userId),
          const SizedBox(height: AppSpacing.sm),

          // Start date
          _buildVoucherInfoRow('Inicio', formatDate(reservation.fechaInicio)),
          const SizedBox(height: AppSpacing.sm),

          // End date
          _buildVoucherInfoRow('Fin', formatDate(reservation.fechaFin)),
          const SizedBox(height: AppSpacing.sm),

          // Duration
          _buildVoucherInfoRow(
            'Duración',
            '${reservation.diasAlquiler} día${reservation.diasAlquiler > 1 ? 's' : ''}',
          ),
          const SizedBox(height: AppSpacing.sm),

          // Total
          _buildVoucherInfoRow(
            'Total',
            '\$${reservation.precioTotal.toStringAsFixed(2)}',
            valueColor: AppColors.primary,
            isBold: true,
          ),
          const SizedBox(height: AppSpacing.md),

          // Time
          Center(
            child: Text(
              _formatTime(reservation.fechaInicio),
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Divider
          Container(
            height: 1,
            color: AppColors.grey,
          ),
          const SizedBox(height: AppSpacing.md),

          // Welcome message
          Text(
            '¡Hola ${reservation.userName ?? 'Usuario'}! 👋',
            style: const TextStyle(
              fontSize: AppFontSizes.md,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          const Text(
            'Agradecemos tu confianza al elegirnos para tu próximo viaje. Esta es la información oficial de tu reserva.\n\nSi tienes alguna pregunta sobre el vehículo, las condiciones de alquiler, disponibilidad de accesorios, o cualquier otro detalle, responde aquí y te ayudaré con gusto.\n\n¡Estamos aquí para asegurarnos de que tengas la mejor experiencia posible!',
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSizes.sm,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? AppFontSizes.md : AppFontSizes.sm,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
