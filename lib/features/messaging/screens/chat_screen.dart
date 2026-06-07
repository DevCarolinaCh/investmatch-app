import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/models/user_model.dart';

final chatMessagesProvider =
    FutureProvider.family<List<MessageModel>, String>((ref, conversationId) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getMessages(conversationId);
  return data
      .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String projectTitle;

  const ChatScreen({
    required this.conversationId,
    required this.projectTitle,
    super.key,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <MessageModel>[];
  late io.Socket _socket;
  bool _isConnected = false;
  bool _isTyping = false;
  String? _remoteTyping;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _loadMessages();
  }

  void _connectSocket() {
    _socket = io.io(
      AppConstants.baseUrl.replaceFirst('/v1', ''),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket.onConnect((_) {
      setState(() => _isConnected = true);
      _socket.emit('join', {'conversationId': widget.conversationId});
    });

    _socket.on(AppConstants.wsEventMessage, (data) {
      final msg = MessageModel.fromJson(data as Map<String, dynamic>);
      setState(() {
        _messages.add(msg);
        _remoteTyping = null;
      });
      _scrollToBottom();
    });

    _socket.on(AppConstants.wsEventTyping, (data) {
      final userId = data['userId'] as String?;
      final currentUserId = ref.read(authNotifierProvider).valueOrNull?.id;
      if (userId != currentUserId) {
        setState(() => _remoteTyping = data['name'] as String?);
      }
    });

    _socket.onDisconnect((_) {
      setState(() => _isConnected = false);
    });
  }

  Future<void> _loadMessages() async {
    final api = ref.read(apiServiceProvider);
    final data = await api.getMessages(widget.conversationId);
    setState(() {
      _messages.addAll(
        data.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)),
      );
    });
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    _messageCtrl.clear();
    setState(() => _isTyping = false);

    final api = ref.read(apiServiceProvider);
    final data = await api.sendMessage(widget.conversationId, text);
    final msg = MessageModel.fromJson(data);

    _socket.emit(AppConstants.wsEventMessage, {
      'conversationId': widget.conversationId,
      'message': msg.toJson(),
    });

    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  void _onTypingChanged(String value) {
    final wasTyping = _isTyping;
    _isTyping = value.isNotEmpty;

    if (_isTyping != wasTyping) {
      final user = ref.read(authNotifierProvider).valueOrNull;
      _socket.emit(AppConstants.wsEventTyping, {
        'conversationId': widget.conversationId,
        'userId': user?.id,
        'name': user?.fullName,
        'isTyping': _isTyping,
      });
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        ref.watch(authNotifierProvider).valueOrNull?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.projectTitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _isConnected ? AppColors.secondary : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isConnected ? 'Conectado' : 'Reconectando...',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Agendar reunión',
            onPressed: () => _showScheduleMeetingSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de typing
          if (_remoteTyping != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.surfaceVariant,
              child: Text(
                '$_remoteTyping está escribiendo...',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Inter',
                ),
              ),
            ),

          // Lista de mensajes
          Expanded(
            child: _messages.isEmpty
                ? _EmptyChat()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == currentUserId;
                      final showDate = index == 0 ||
                          !_isSameDay(
                            _messages[index - 1].createdAt,
                            msg.createdAt,
                          );
                      final showAvatar = !isMe &&
                          (index == _messages.length - 1 ||
                              _messages[index + 1].senderId != msg.senderId);

                      return Column(
                        children: [
                          if (showDate)
                            _DateDivider(date: msg.createdAt),
                          _MessageBubble(
                            message: msg,
                            isMe: isMe,
                            showAvatar: showAvatar,
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Input de mensaje
          _MessageInput(
            controller: _messageCtrl,
            onSend: _sendMessage,
            onChanged: _onTypingChanged,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showScheduleMeetingSheet(BuildContext context) {
    context.push('/agenda?conversationId=${widget.conversationId}');
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: AppColors.error),
            title: const Text('Reportar conversación'),
            onTap: () {
              Navigator.pop(context);
              // TODO: flujo de reporte
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: const Text('Bloquear usuario'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showAvatar)
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: message.senderAvatarUrl != null
                    ? NetworkImage(message.senderAvatarUrl!)
                    : null,
                child: message.senderAvatarUrl == null
                    ? Text(
                        message.senderName.isNotEmpty
                            ? message.senderName[0]
                            : '?',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.primary),
                      )
                    : null,
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : AppColors.textTertiary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 3),
                        Icon(
                          message.status == MessageStatus.read
                              ? Icons.done_all
                              : Icons.done,
                          size: 12,
                          color: message.status == MessageStatus.read
                              ? Colors.lightBlueAccent
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Hoy';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Ayer';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  const _MessageInput({
    required this.controller,
    required this.onSend,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Adjuntar archivo
          IconButton(
            icon: const Icon(Icons.attach_file_outlined,
                color: AppColors.textSecondary),
            onPressed: () {}, // TODO: adjuntar archivo
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 5,
              minLines: 1,
              maxLength: AppConstants.maxMessageLength,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Escribí un mensaje...',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón enviar
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              final hasText = value.text.trim().isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                child: FloatingActionButton.small(
                  onPressed: hasText ? onSend : null,
                  backgroundColor: hasText ? AppColors.primary : AppColors.border,
                  elevation: 0,
                  child: const Icon(Icons.send_rounded, size: 18),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('¡Iniciá la conversación!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  )),
          const SizedBox(height: 8),
          const Text(
            'Presentate y contá en qué podés ayudar',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
