import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/marketplace_conversation.dart';
import '../../services/marketplace_service.dart';
import 'marketplace_conversation_screen.dart';

enum MessagesInboxFilter { all, buying, selling, unread }

List<MarketplaceConversation> filterInboxConversations({
  required List<MarketplaceConversation> conversations,
  required String currentUserId,
  required MessagesInboxFilter filter,
  required String query,
}) {
  final seenIds = <String>{};
  final normalizedQuery = query.trim().toLowerCase();
  final filtered = <MarketplaceConversation>[];

  for (final conversation in conversations) {
    if (!seenIds.add(conversation.id)) continue;
    if (!_matchesInboxFilter(conversation, currentUserId, filter)) continue;
    if (normalizedQuery.isNotEmpty &&
        !_matchesInboxQuery(conversation, currentUserId, normalizedQuery)) {
      continue;
    }
    filtered.add(conversation);
  }

  return filtered;
}

bool _matchesInboxFilter(
  MarketplaceConversation conversation,
  String currentUserId,
  MessagesInboxFilter filter,
) {
  switch (filter) {
    case MessagesInboxFilter.all:
      return true;
    case MessagesInboxFilter.buying:
      return conversation.listingId.isNotEmpty &&
          conversation.buyerId == currentUserId;
    case MessagesInboxFilter.selling:
      return conversation.listingId.isNotEmpty &&
          conversation.sellerId == currentUserId;
    case MessagesInboxFilter.unread:
      return conversation.unreadFor(currentUserId) > 0;
  }
}

bool _matchesInboxQuery(
  MarketplaceConversation conversation,
  String currentUserId,
  String query,
) {
  final haystack = [
    conversation.otherUserName(currentUserId),
    conversation.otherUserId(currentUserId),
    conversation.lastMessage,
    conversation.listingTitle,
    conversation.listingCity,
    conversation.reelTitle,
  ].join(' ').toLowerCase();
  return haystack.contains(query);
}

/// Unified premium marketplace inbox: exactly one row per other user.
///
/// The backend returns one canonical conversation per participant pair. Flutter
/// keeps a client-side safety dedupe for migration leftovers; there is no
/// picker, no grouped participant sheet, and no per-context row duplication.
class MarketplaceMessagesScreen extends StatefulWidget {
  const MarketplaceMessagesScreen({super.key, this.initialConversationId});

  /// When set (for example from a notification tap), the inbox auto-opens this
  /// conversation after the first load completes.
  final String? initialConversationId;

  @override
  State<MarketplaceMessagesScreen> createState() =>
      _MarketplaceMessagesScreenState();
}

class _MarketplaceMessagesScreenState extends State<MarketplaceMessagesScreen> {
  final _searchController = TextEditingController();
  List<MarketplaceConversation> _conversations = const [];
  MessagesInboxFilter _filter = MessagesInboxFilter.all;
  bool _loading = true;
  String? _error;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInbox();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

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
      final raw = await MarketplaceService.instance.fetchInbox();
      final result = dedupeInboxConversations(raw, _uid);
      debugPrint(
        '[16F-D] inbox_load before=${result.before} '
        'after=${result.after} hidden_self=${result.hiddenSelf}',
      );
      if (!mounted) return;
      setState(() {
        _conversations = result.conversations;
        _loading = false;
      });

      final pendingId = widget.initialConversationId;
      if (pendingId != null && pendingId.isNotEmpty && mounted) {
        final match = result.conversations
            .where((conversation) => conversation.id == pendingId)
            .firstOrNull;
        if (match != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openConversation(match);
          });
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'mkt.messages.serviceUnavailable'.tr();
      });
    }
  }

  Future<void> _openConversation(MarketplaceConversation conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MarketplaceConversationScreen(conversation: conversation),
      ),
    );
    if (mounted) _loadInbox();
  }

  Future<void> _archiveConversation(MarketplaceConversation conv) async {
    final idx = _conversations.indexOf(conv);
    setState(() {
      _conversations = [..._conversations.where((c) => c.id != conv.id)];
    });
    try {
      await MarketplaceService.instance.archiveConversation(conv.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('mkt.inbox.archived'.tr())));
      }
    } catch (_) {
      if (mounted) {
        final updated = List<MarketplaceConversation>.from(_conversations);
        if (idx >= 0 && idx <= updated.length) {
          updated.insert(idx, conv);
        } else {
          updated.add(conv);
        }
        setState(() => _conversations = updated);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('mkt.inbox.actionFailed'.tr())));
      }
    }
  }

  Future<void> _deleteConversation(MarketplaceConversation conv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('mkt.inbox.deleteConfirmTitle'.tr()),
        content: Text('mkt.inbox.deleteConfirmBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'mkt.inbox.deleteForMe'.tr(),
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final idx = _conversations.indexOf(conv);
    setState(() {
      _conversations = [..._conversations.where((c) => c.id != conv.id)];
    });
    try {
      await MarketplaceService.instance.deleteConversationForMe(conv.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('mkt.inbox.deleted'.tr())));
      }
    } catch (_) {
      if (mounted) {
        final updated = List<MarketplaceConversation>.from(_conversations);
        if (idx >= 0 && idx <= updated.length) {
          updated.insert(idx, conv);
        } else {
          updated.add(conv);
        }
        setState(() => _conversations = updated);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('mkt.inbox.actionFailed'.tr())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final filtered = filterInboxConversations(
      conversations: _conversations,
      currentUserId: _uid,
      filter: _filter,
      query: _searchController.text,
    );

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
      body: Column(
        children: [
          _InboxControls(
            controller: _searchController,
            filter: _filter,
            isDark: isDark,
            onFilterChanged: (filter) => setState(() => _filter = filter),
          ),
          Expanded(child: _buildContent(isDark, filtered)),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, List<MarketplaceConversation> filtered) {
    if (_loading) {
      return const _InboxSkeleton();
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
    if (filtered.isEmpty) {
      return _InboxState(
        icon: Icons.search_off_rounded,
        title: 'mkt.messages.noSearchResults'.tr(),
        subtitle: 'mkt.messages.noSearchResultsHint'.tr(),
      );
    }
    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: _loadInbox,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final conversation = filtered[index];
          return Dismissible(
            key: ValueKey(conversation.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              await _deleteConversation(conversation);
              return false;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsetsDirectional.only(end: 22),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.red,
              ),
            ),
            child: _ConversationTile(
              conversation: conversation,
              currentUserId: _uid,
              isDark: isDark,
              onTap: () => _openConversation(conversation),
              onArchive: () => _archiveConversation(conversation),
              onDelete: () => _deleteConversation(conversation),
            ),
          );
        },
      ),
    );
  }
}

class _InboxControls extends StatelessWidget {
  final TextEditingController controller;
  final MessagesInboxFilter filter;
  final bool isDark;
  final ValueChanged<MessagesInboxFilter> onFilterChanged;

  const _InboxControls({
    required this.controller,
    required this.filter,
    required this.isDark,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.background : AppColors.lightBackground;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : AppColors.lightBorder,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
        child: Column(
          children: [
            TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'mkt.messages.searchHint'.tr(),
                hintStyle: TextStyle(color: muted),
                prefixIcon: Icon(Icons.search_rounded, color: muted),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).deleteButtonTooltip,
                        onPressed: controller.clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: isDark ? AppColors.input : AppColors.lightCard,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white10 : AppColors.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.orange),
                ),
              ),
              style: TextStyle(color: text, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: MessagesInboxFilter.values
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: _FilterChipButton(
                          label: _filterLabel(item).tr(),
                          selected: item == filter,
                          isDark: isDark,
                          onTap: () => onFilterChanged(item),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(MessagesInboxFilter filter) {
    switch (filter) {
      case MessagesInboxFilter.all:
        return 'mkt.messages.filterAll';
      case MessagesInboxFilter.buying:
        return 'mkt.messages.filterBuying';
      case MessagesInboxFilter.selling:
        return 'mkt.messages.filterSelling';
      case MessagesInboxFilter.unread:
        return 'mkt.messages.filterUnread';
    }
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = AppColors.orange.withValues(alpha: isDark ? .22 : .13);
    return Material(
      color: selected
          ? selectedBg
          : (isDark ? AppColors.card : AppColors.lightCard),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.orange.withValues(alpha: .7)
                  : (isDark ? Colors.white10 : AppColors.lightBorder),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? AppColors.orange
                  : (isDark ? AppColors.gray : AppColors.lightGray),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final MarketplaceConversation conversation;
  final String currentUserId;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.isDark,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final avatar = conversation.otherUserPhoto(currentUserId);
    final name = conversation.otherUserName(currentUserId);
    final otherId = conversation.otherUserId(currentUserId);
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
        onLongPress: onArchive,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : AppColors.lightBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ConversationAvatar(url: avatar, isDark: isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isNotEmpty ? name : otherId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          _UnreadBadge(count: unread),
                        ],
                      ],
                    ),
                    if (_hasCompactContext(conversation)) ...[
                      const SizedBox(height: 8),
                      _CompactContextStrip(
                        conversation: conversation,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 2),
              _ConversationMenu(
                isDark: isDark,
                onArchive: onArchive,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasCompactContext(MarketplaceConversation conversation) {
    return conversation.listingId.isNotEmpty ||
        conversation.reelId.isNotEmpty ||
        conversation.listingTitle.isNotEmpty ||
        conversation.reelTitle.isNotEmpty;
  }
}

class _ConversationAvatar extends StatelessWidget {
  final String url;
  final bool isDark;

  const _ConversationAvatar({required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: 54,
      height: 54,
      child: url.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _AvatarPlaceholder(isDark: isDark),
            )
          : _AvatarPlaceholder(isDark: isDark),
    ),
  );
}

class _AvatarPlaceholder extends StatelessWidget {
  final bool isDark;

  const _AvatarPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.orange.withValues(alpha: isDark ? .18 : .11),
    child: const Icon(Icons.person_outline_rounded, color: AppColors.orange),
  );
}

class _CompactContextStrip extends StatelessWidget {
  final MarketplaceConversation conversation;
  final bool isDark;

  const _CompactContextStrip({
    required this.conversation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isListing =
        conversation.listingId.isNotEmpty ||
        conversation.listingTitle.isNotEmpty;
    final title = isListing
        ? conversation.listingTitle
        : conversation.reelTitle;
    final image = isListing
        ? conversation.listingImage
        : conversation.reelThumbnailUrl;
    final label = isListing
        ? 'mkt.inbox.contextListing'.tr()
        : 'mkt.inbox.contextReel'.tr();
    final color = isListing ? AppColors.orange : Colors.deepPurpleAccent;
    final icon = isListing
        ? Icons.shopping_bag_outlined
        : Icons.play_circle_outline;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            width: 28,
            height: 28,
            child: image.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _ContextThumbFallback(color: color, icon: icon),
                  )
                : _ContextThumbFallback(color: color, icon: icon),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            title.isEmpty ? label : '$label · $title',
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
    );
  }
}

class _ContextThumbFallback extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _ContextThumbFallback({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    color: color.withValues(alpha: .12),
    child: Icon(icon, color: color, size: 16),
  );
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.orange,
      borderRadius: BorderRadius.circular(999),
    ),
    alignment: Alignment.center,
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

enum _InboxAction { archive, delete }

class _ConversationMenu extends StatelessWidget {
  final bool isDark;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _ConversationMenu({
    required this.isDark,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_InboxAction>(
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      icon: Icon(
        Icons.more_vert_rounded,
        color: isDark ? AppColors.gray : AppColors.lightGray,
      ),
      color: isDark ? AppColors.card2 : AppColors.lightCard,
      onSelected: (value) {
        switch (value) {
          case _InboxAction.archive:
            onArchive();
            break;
          case _InboxAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _InboxAction.archive,
          child: Text('mkt.inbox.archiveConversation'.tr()),
        ),
        PopupMenuItem(
          value: _InboxAction.delete,
          child: Text('mkt.inbox.deleteForMe'.tr()),
        ),
      ],
    );
  }
}

class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.card : AppColors.lightCard;
    final line = isDark ? AppColors.card2 : AppColors.lightCard2;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            _SkeletonBox(size: 54, radius: 999, color: line),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 140, height: 13, color: line),
                  const SizedBox(height: 10),
                  _SkeletonBox(width: double.infinity, height: 11, color: line),
                  const SizedBox(height: 9),
                  _SkeletonBox(width: 96, height: 10, color: line),
                ],
              ),
            ),
          ],
        ),
      ),
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
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: AppColors.orange, size: 34),
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }
}
