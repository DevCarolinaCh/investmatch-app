import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/message_model.dart';

final conversationsProvider =
    FutureProvider<List<ConversationModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getConversations();
  return data
      .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Nuevo mensaje',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error: $e'),
              TextButton(
                onPressed: () => ref.invalidate(conversationsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (convos) => convos.isEmpty
            ? _EmptyConversations()
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(conversationsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: convos.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 80),
                  itemBuilder: (context, index) =>
                      _ConversationTile(conversation: convos[index]),
                ),
              ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final ConversationModel conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId =
        ref.watch(authNotifierProvider).valueOrNull?.id ?? '';
    final isInvestor = conversation.investorId == currentUserId;
    final counterpartName =
        isInvestor ? conversation.founderName : conversation.investorName;
    final counterpartAvatar =
        isInvestor ? conversation.founderAvatarUrl : conversation.investorAvatarUrl;
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: () => context.push(
        '/chat/${conversation.id}?title=${Uri.encodeComponent(conversation.projectTitle)}',
      ),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: counterpartAvatar != null
                ? NetworkImage(counterpartAvatar)
                : null,
            child: counterpartAvatar == null
                ? Text(
                    counterpartName.isNotEmpty ? counterpartName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  )
                : null,
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    conversation.unreadCount > 9
                        ? '9+'
                        : '${conversation.unreadCount}',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              counterpartName,
              style: TextStyle(
                fontWeight:
                    hasUnread ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
                fontFamily: 'Inter',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeago.format(conversation.updatedAt, locale: 'es'),
            style: TextStyle(
              fontSize: 11,
              color: hasUnread ? AppColors.primary : AppColors.textTertiary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conversation.projectTitle,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter'),
          ),
          const SizedBox(height: 2),
          Text(
            conversation.lastMessage?.content ?? 'Sin mensajes aún',
            style: TextStyle(
              fontSize: 13,
              color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
              fontFamily: 'Inter',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyConversations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 72, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Sin conversaciones todavía',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explorá proyectos y contactá a emprendedores',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search),
            label: const Text('Explorar proyectos'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 48),
            ),
          ),
        ],
      ),
    );
  }
}
