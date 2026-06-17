import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/marketplace_conversation.dart';
import '../../services/marketplace_service.dart';
import 'marketplace_conversation_screen.dart';

class MarketplaceMessagesScreen extends StatefulWidget {
  const MarketplaceMessagesScreen({super.key});

  @override
  State<MarketplaceMessagesScreen> createState() =>
      _MarketplaceMessagesScreenState();
}

class _MarketplaceMessagesScreenState extends State<MarketplaceMessagesScreen> {
  List<MarketplaceConversation> _conversations = const [];
  bool _loading = true;
  String? _error;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    if (_uid.isEmpty) {
      setState(() {
        _loading = false;
        _conversations = const [];
        _error = 'mkt.messages.loginRequired'.tr();
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final conversations = await MarketplaceService.instance.fetchInbox();
      final deduped = dedupeInboxConversations(conversations, _uid);
      debugPrint(
        '[Marketplace16F-A] inbox_dedup before=${deduped.before} '
        'after=${deduped.after} hidden_self=${deduped.hiddenSelf} grouped=0',
      );
      if (!mounted) return;
      setState(() {
        _conversations = deduped.conversations;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'mkt.messages.serviceUnavailable'.tr();
      });
    }
  }

  Future<void> _open(MarketplaceConversation conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MarketplaceConversationScreen(conversation: conversation),
      ),
    );
    if (mounted) _loadInbox();
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
          'mkt.messages.title'.tr(),
          style: TextStyle(color: text, fontWeight: FontWeight.w900),
        ),
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }
    if (_error != null) {
      return _InboxState(
        icon: Icons.cloud_off_outlined,
        title: _error!,
        subtitle: _uid.isEmpty ? null : 'mkt.messages.honestFallback'.tr(),
        action: _uid.isEmpty ? null : _loadInbox,
      );
    }
    if (_conversations.isEmpty) {
      return _InboxState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'mkt.messages.noConversations'.tr(),
        subtitle: 'mkt.messages.emptyHint'.tr(),
      );
    }
    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: _loadInbox,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final conversation = _conversations[index];
          return _ConversationTile(
            conversation: conversation,
            currentUserId: _uid,
            isDark: isDark,
            onTap: () => _open(conversation),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final MarketplaceConversation conversation;
  final String currentUserId;
  final bool isDark;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final otherName = conversation.otherUserName(currentUserId).trim();
    final unread = conversation.unreadFor(currentUserId);
    final timestamp = conversation.lastMessageAt == null
        ? ''
        : DateFormat.MMMd(
            context.locale.languageCode,
          ).add_Hm().format(conversation.lastMessageAt!.toLocal());

    return Material(
      color: isDark ? AppColors.card : AppColors.lightCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white12 : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: conversation.listingImage.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: conversation.listingImage,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const _TileIcon(),
                        )
                      : const _TileIcon(),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.listingTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (timestamp.isNotEmpty)
                          Text(
                            timestamp,
                            style: TextStyle(color: muted, fontSize: 9),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      otherName.isNotEmpty
                          ? otherName
                          : (currentUserId == conversation.sellerId
                                ? 'mkt.messages.buyer'.tr()
                                : 'mkt.messages.seller'.tr()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage.isEmpty
                                ? 'mkt.messages.startConversation'.tr()
                                : conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unread',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.orange.withValues(alpha: .1),
    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.orange),
  );
}

class _InboxState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? action;

  const _InboxState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.orange, size: 52),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 7),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: action,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('mkt.messages.retry'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
