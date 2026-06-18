import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/conversation_model.dart';
import '../../services/auth_service.dart';
import '../../services/message_service.dart';
import 'chat_screen.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  final AuthService auth = AuthService.instance;
  final _searchController = TextEditingController();
  late final MessageService service;

  List<ConversationModel> items = [];
  bool loading = true;
  bool showUnreadOnly = false;
  String? error;

  @override
  void initState() {
    super.initState();
    service = MessageService(baseUrl: widget.baseUrl);
    _searchController.addListener(() => setState(() {}));
    loadInbox();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadInbox() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await service.getInbox();
      if (!mounted) return;
      setState(() {
        items = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'mkt.inbox.loadFailed'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUserId ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final filtered = _filteredItems(uid);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        title: Text(
          'mkt.messages.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          _LegacyInboxControls(
            controller: _searchController,
            showUnreadOnly: showUnreadOnly,
            isDark: isDark,
            onUnreadChanged: (value) => setState(() => showUnreadOnly = value),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadInbox,
              color: AppColors.orange,
              child: _buildContent(uid, filtered, isDark),
            ),
          ),
        ],
      ),
    );
  }

  List<ConversationModel> _filteredItems(String uid) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((conversation) {
      if (showUnreadOnly && conversation.unreadFor(uid) == 0) return false;
      if (query.isEmpty) return true;
      final haystack = [
        conversation.otherUserName(uid),
        conversation.otherUserId(uid),
        conversation.lastMessage,
        conversation.reelTitle,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Widget _buildContent(
    String uid,
    List<ConversationModel> filtered,
    bool isDark,
  ) {
    if (loading) return const _LegacyInboxSkeleton();
    if (error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          _LegacyState(
            icon: Icons.cloud_off_outlined,
            title: error!,
            isDark: isDark,
            action: loadInbox,
          ),
        ],
      );
    }
    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          _LegacyState(
            icon: Icons.mark_chat_unread_outlined,
            title: 'mkt.inbox.empty'.tr(),
            subtitle: 'mkt.messages.emptyHint'.tr(),
            isDark: isDark,
          ),
        ],
      );
    }
    if (filtered.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          _LegacyState(
            icon: Icons.search_off_rounded,
            title: 'mkt.messages.noSearchResults'.tr(),
            subtitle: 'mkt.messages.noSearchResultsHint'.tr(),
            isDark: isDark,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final conversation = filtered[index];
        return _LegacyConversationTile(
          conversation: conversation,
          currentUserId: uid,
          isDark: isDark,
          onTap: () {
            final otherName = conversation.otherUserName(uid);
            final otherPhoto = conversation.otherUserPhoto(uid);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  baseUrl: widget.baseUrl,
                  conversationId: conversation.id,
                  recipientId: conversation.otherUserId(uid),
                  recipientName: otherName,
                  recipientAvatarUrl: otherPhoto,
                ),
              ),
            ).then((_) => loadInbox());
          },
        );
      },
    );
  }
}

class _LegacyInboxControls extends StatelessWidget {
  final TextEditingController controller;
  final bool showUnreadOnly;
  final bool isDark;
  final ValueChanged<bool> onUnreadChanged;

  const _LegacyInboxControls({
    required this.controller,
    required this.showUnreadOnly,
    required this.isDark,
    required this.onUnreadChanged,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final text = isDark ? AppColors.text : AppColors.lightText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
      child: Column(
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: text, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'mkt.messages.searchHint'.tr(),
              hintStyle: TextStyle(color: muted),
              prefixIcon: Icon(Icons.search_rounded, color: muted),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: controller.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: isDark ? AppColors.input : AppColors.lightCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilterChip(
              selected: showUnreadOnly,
              onSelected: onUnreadChanged,
              label: Text('mkt.messages.filterUnread'.tr()),
              avatar: const Icon(Icons.mark_chat_unread_outlined, size: 16),
              selectedColor: AppColors.orange.withValues(alpha: .18),
              checkmarkColor: AppColors.orange,
              labelStyle: TextStyle(
                color: showUnreadOnly ? AppColors.orange : muted,
                fontWeight: FontWeight.w900,
              ),
              side: BorderSide(
                color: showUnreadOnly
                    ? AppColors.orange.withValues(alpha: .7)
                    : (isDark ? Colors.white10 : AppColors.lightBorder),
              ),
              backgroundColor: isDark ? AppColors.card : AppColors.lightCard,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final bool isDark;
  final VoidCallback onTap;

  const _LegacyConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final otherName = conversation.otherUserName(currentUserId);
    final otherPhoto = conversation.otherUserPhoto(currentUserId);
    final unread = conversation.unreadFor(currentUserId);
    final timestamp = conversation.lastMessageAt == null
        ? ''
        : DateFormat.MMMd(
            context.locale.languageCode,
          ).add_Hm().format(conversation.lastMessageAt!.toLocal());

    return Material(
      color: isDark ? AppColors.card : AppColors.lightCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: AppColors.orange.withValues(alpha: .14),
                backgroundImage: otherPhoto.startsWith('http')
                    ? CachedNetworkImageProvider(otherPhoto)
                    : null,
                child: otherPhoto.startsWith('http')
                    ? null
                    : const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.orange,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: text,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (timestamp.isNotEmpty)
                          Text(
                            timestamp,
                            style: TextStyle(
                              color: unread > 0 ? AppColors.orange : muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      conversation.lastMessage.isEmpty
                          ? 'mkt.inbox.newMessage'.tr()
                          : conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread > 0 ? text : muted,
                        fontSize: 13,
                        fontWeight: unread > 0
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    if (conversation.reelTitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.play_circle_outline_rounded,
                            color: Colors.deepPurpleAccent,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              conversation.reelTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (unread > 0)
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 21,
                    minHeight: 21,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded, color: muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegacyInboxSkeleton extends StatelessWidget {
  const _LegacyInboxSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.card : AppColors.lightCard;
    final line = isDark ? AppColors.card2 : AppColors.lightCard2;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _SkeletonBox(size: 54, radius: 999, color: line),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 130, height: 13, color: line),
                  const SizedBox(height: 10),
                  _SkeletonBox(width: double.infinity, height: 11, color: line),
                ],
              ),
            ),
          ],
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: 6,
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double? size;
  final double radius;
  final Color color;

  const _SkeletonBox({
    this.width,
    this.height,
    this.size,
    this.radius = 6,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size ?? width,
    height: size ?? height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _LegacyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDark;
  final VoidCallback? action;

  const _LegacyState({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isDark,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.orange, size: 44),
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
              style: TextStyle(color: muted, fontSize: 12, height: 1.35),
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
    );
  }
}
