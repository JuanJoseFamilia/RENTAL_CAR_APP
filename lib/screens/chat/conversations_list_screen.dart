import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/conversation_model.dart';
import '../../services/reservation_service.dart';
import '../../models/reservation_model.dart';
import '../../utils/constants.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _historicalFilter = 'todos'; // todos, completados, cancelados

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      return const Center(child: Text('Inicia sesión para ver tus mensajes'));
    }

    final isAdmin = authProvider.currentUser?.rol == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Conversaciones (admin)' : 'Mensajes',
          style: const TextStyle(color: AppColors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Chat Activos'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chat Activos
          _buildActiveChatsTab(isAdmin, userId, context),
          // Histórico
          _buildHistoricalChatsTab(isAdmin, userId, context),
        ],
      ),
    );
  }

  Widget _buildActiveChatsTab(bool isAdmin, String userId, BuildContext context) {
    return StreamBuilder<List<ConversationModel>>(
      stream: isAdmin
          ? context.read<ChatProvider>().streamAllConversations()
          : context.read<ChatProvider>().streamUserConversations(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final convs = snapshot.data ?? [];

        // Filtrar solo chats activos (reservas en proceso)
        final activeChats = <(ConversationModel, ReservationModel?)>[];
        final futures = <Future<ReservationModel?>>[];
        final conversationsList = <ConversationModel>[];

        for (final conv in convs) {
          conversationsList.add(conv);
          futures.add(ReservationService().getReservationWithFullData(conv.reservationId));
        }

        return FutureBuilder<List<ReservationModel?>>(
          future: Future.wait(futures),
          builder: (context, snapReservations) {
            if (snapReservations.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final reservations = snapReservations.data ?? [];

            for (int i = 0; i < conversationsList.length; i++) {
              final res = reservations[i];
              // Mostrar solo chats de reservas en proceso (pendiente o confirmada)
              if (res != null && (res.estado == 'pendiente' || res.estado == 'confirmada')) {
                activeChats.add((conversationsList[i], res));
              }
            }

            if (activeChats.isEmpty) {
              return const Center(child: Text('No tienes chats activos'));
            }

            return ListView.separated(
              itemCount: activeChats.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final (conv, res) = activeChats[index];
                return _buildConversationTile(
                  context,
                  conv,
                  res,
                  isAdmin,
                  userId,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHistoricalChatsTab(bool isAdmin, String userId, BuildContext context) {
    return Column(
      children: [
        // Filtro
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Filtrar por:',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              DropdownButton<String>(
                value: _historicalFilter,
                items: const [
                  DropdownMenuItem(value: 'todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'completados', child: Text('Completados')),
                  DropdownMenuItem(value: 'cancelados', child: Text('Cancelados')),
                ],
                onChanged: (value) {
                  setState(() {
                    _historicalFilter = value ?? 'todos';
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ConversationModel>>(
            stream: isAdmin
                ? context.read<ChatProvider>().streamAllConversations()
                : context.read<ChatProvider>().streamUserConversations(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final convs = snapshot.data ?? [];

              // Filtrar solo chats históricos (completados y cancelados)
              final historicalChats = <(ConversationModel, ReservationModel?)>[];
              final futures = <Future<ReservationModel?>>[];
              final conversationsList = <ConversationModel>[];

              for (final conv in convs) {
                conversationsList.add(conv);
                futures.add(ReservationService().getReservationWithFullData(conv.reservationId));
              }

              return FutureBuilder<List<ReservationModel?>>(
                future: Future.wait(futures),
                builder: (context, snapReservations) {
                  if (snapReservations.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reservations = snapReservations.data ?? [];

                  for (int i = 0; i < conversationsList.length; i++) {
                    final res = reservations[i];
                    if (res != null && (res.estado == 'completada' || res.estado == 'cancelada')) {
                      // Aplicar filtro
                      if (_historicalFilter == 'todos' ||
                          (_historicalFilter == 'completados' && res.estado == 'completada') ||
                          (_historicalFilter == 'cancelados' && res.estado == 'cancelada')) {
                        historicalChats.add((conversationsList[i], res));
                      }
                    }
                  }

                  if (historicalChats.isEmpty) {
                    return const Center(child: Text('No tienes chats en el histórico'));
                  }

                  return ListView.separated(
                    itemCount: historicalChats.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final (conv, res) = historicalChats[index];
                      return _buildConversationTile(
                        context,
                        conv,
                        res,
                        isAdmin,
                        userId,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    ConversationModel conv,
    ReservationModel? res,
    bool isAdmin,
    String userId,
  ) {
    final userLabel = isAdmin ? (res?.userName ?? conv.userId) : res?.vehicleNombre;
    final vehicleLabel = !isAdmin
        ? (res != null && res.vehicleMarca != null ? '${res.vehicleMarca} ${res.vehicleModelo}' : conv.vehicleId)
        : null;
    final lastMsg = conv.lastMessage ?? 'Sin mensajes';
    final updated = DateFormat.yMd().add_Hm().format(conv.updatedAt);

    // Color del borde según estado
    Color borderColor = AppColors.textSecondary;
    if (res != null) {
      if (res.estado == 'completada') {
        borderColor = AppColors.success;
      } else if (res.estado == 'cancelada') {
        borderColor = AppColors.error;
      }
    }

    return StreamBuilder<int>(
      stream: context.read<ChatProvider>().streamUnreadCountForConversation(conv.id, userId),
      builder: (context, unreadSnap) {
        final hasUnread = (unreadSnap.data ?? 0) > 0;

        return Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: borderColor, width: 4)),
          ),
          child: ListTile(
            title: Row(
              children: [
                Expanded(child: Text(userLabel ?? 'Desconocido')),
                if (hasUnread)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (vehicleLabel != null) Text('Vehículo: $vehicleLabel'),
                if (res != null)
                  Text(
                    'Estado: ${res.estadoTexto}',
                    style: TextStyle(
                      fontSize: 12,
                      color: res.estado == 'completada'
                          ? AppColors.success
                          : res.estado == 'cancelada'
                              ? AppColors.error
                              : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Último: $lastMsg',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      updated,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).pushNamed(
                '/chat',
                arguments: {
                  'conversationId': conv.id,
                  'reservationId': conv.reservationId,
                },
              );
            },
          ),
        );
      },
    );
  }
}
