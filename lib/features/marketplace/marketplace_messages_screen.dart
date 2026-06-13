import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/config/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class MarketplaceMessagesScreen extends StatefulWidget {
  const MarketplaceMessagesScreen({super.key});

  @override
  State<MarketplaceMessagesScreen> createState() =>
      _MarketplaceMessagesScreenState();
}

class _MarketplaceMessagesScreenState
    extends State<MarketplaceMessagesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadInbox();
  }

  Future<List<Map<String, dynamic>>> _loadInbox() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    try {
      final response = await ApiService.instance.get(
        ApiEndpoints.messagesInbox,
        authorized: true,
      );
      final map = response is Map ? response : null;
      final list = response is List
          ? response
          : map?['conversations'] as List? ??
            map?['items'] as List? ??
            const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final text = isDark ? AppColors.text : AppColors.lightText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'marketplace.messages'.tr(),
          style: TextStyle(color: text, fontWeight: FontWeight.w900),
        ),
        backgroundColor: bg,
        iconTheme: IconThemeData(color: text),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }
          final conversations = snap.data ?? [];
          if (conversations.isEmpty) {
            return _EmptyMessages(isDark: isDark);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) =>
                _ConversationTile(data: conversations[i], isDark: isDark),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _ConversationTile({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.card : AppColors.lightCard;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final border = isDark ? Colors.white12 : AppColors.lightBorder;

    final otherName = data['otherUserName']?.toString() ??
        data['sellerName']?.toString() ??
        data['buyerName']?.toString() ??
        '—';
    final lastMsg = data['lastMessage']?.toString() ?? '';
    final avatar = data['otherUserAvatar']?.toString() ?? '';
    final unread = (data['unreadCount'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.orange.withValues(alpha: .18),
            backgroundImage:
                avatar.startsWith('http') ? NetworkImage(avatar) : null,
            child: avatar.startsWith('http')
                ? null
                : Icon(Icons.person_rounded, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otherName,
                    style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                if (lastMsg.isNotEmpty)
                  Text(lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          ),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}

class _EmptyMessages extends StatelessWidget {
  final bool isDark;

  const _EmptyMessages({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.orange, size: 56),
            const SizedBox(height: 16),
            Text(
              'marketplace.messages'.tr(),
              style: TextStyle(
                  color: text, fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'marketplace.messagesEmpty'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'marketplace.messagesComingSoon'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: muted, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
