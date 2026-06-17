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
  List<InboxParticipantGroup> _groups = const [];
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
        _groups = const [];
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
      final result = groupInboxByParticipant(raw, _uid);
      debugPrint(
        '[Marketplace16F-C] inbox_group before=${result.before} '
        'after=${result.after} hidden_self=${result.hiddenSelf} '
        'contexts=${result.contexts}',
      );
      if (!mounted) return;
      setState(() {
        _groups = result.groups;
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

  Future<void> _openGroup(InboxParticipantGroup group) async {
    if (group.conversations.length == 1) {
      await _openConversation(group.conversations.first);
      return;
    }
    // Multiple conversations with the same person — show a picker.
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConversationPickerSheet(
        group: group,
        onPick: _openConversation,
      ),
    );
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

  Future<void> _archiveGroup(InboxParticipantGroup group) async {
    setState(() {
      _groups = _groups.where((g) => g.otherUserId != group.otherUserId).toList();
    });
    try {
      for (final conv in group.conversations) {
        await MarketplaceService.instance.archiveConversation(conv.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('mkt.inbox.archived'.tr())),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _groups = [group, ..._groups]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('mkt.inbox.actionFailed'.tr())),
        );
      }
    }
  }

  Future<void> _deleteGroup(InboxParticipantGroup group) async {
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
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _groups = _groups.where((g) => g.otherUserId != group.otherUserId).toList();
    });
    try {
      for (final conv in group.conversations) {
        await MarketplaceService.instance.deleteConversationForMe(conv.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('mkt.inbox.deleted'.tr())),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _groups = [group, ..._groups]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('mkt.inbox.actionFailed'.tr())),
        );
      }
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
    if (_groups.isEmpty) {
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
        itemCount: _groups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final group = _groups[index];
          return Dismissible(
            key: ValueKey(group.otherUserId),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              await _deleteGroup(group);
              return false;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            ),
            child: _ParticipantTile(
              group: group,
              isDark: isDark,
              onTap: () => _openGroup(group),
              onArchive: () => _archiveGroup(group),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile
// ---------------------------------------------------------------------------

class _ParticipantTile extends StatelessWidget {
  final InboxParticipantGroup group;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  const _ParticipantTile({
    required this.group,
    required this.isDark,
    required this.onTap,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final image = group.leadingImage;
    final timestamp = group.latestMessageAt == null
        ? ''
        : DateFormat.MMMd(
            context.locale.languageCode,
          ).add_Hm().format(group.latestMessageAt!.toLocal());

    return Material(
      color: isDark ? AppColors.card : AppColors.lightCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        onLongPress: onArchive,
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
              // User avatar (circle)
              ClipOval(
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: image.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _AvatarPlaceholder(),
                        )
                      : _AvatarPlaceholder(),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + timestamp
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.otherUserName.isNotEmpty
                                ? group.otherUserName
                                : group.otherUserId,
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
                            style: TextStyle(color: muted, fontSize: 9),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Context chips
                    _ContextChips(group: group),
                    const SizedBox(height: 4),
                    // Latest message + unread badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.latestMessage.isEmpty
                                ? 'mkt.messages.startConversation'.tr()
                                : group.latestMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: group.totalUnread > 0 ? text : muted,
                              fontSize: 12,
                              fontWeight: group.totalUnread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (group.totalUnread > 0)
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
                              '${group.totalUnread}',
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
              // Arrow when there are multiple conversations to pick from
              if (group.conversations.length > 1)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: muted,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextChips extends StatelessWidget {
  final InboxParticipantGroup group;

  const _ContextChips({required this.group});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (group.listingCount > 0) {
      chips.add(_Chip(
        label: group.listingCount == 1
            ? 'mkt.inbox.contextListing'.tr()
            : '${group.listingCount} ${'mkt.inbox.contextListings'.tr()}',
        color: AppColors.orange,
      ));
    }
    if (group.reelCount > 0) {
      chips.add(_Chip(
        label: group.reelCount == 1
            ? 'mkt.inbox.contextReel'.tr()
            : '${group.reelCount} ${'mkt.inbox.contextReels'.tr()}',
        color: Colors.purple,
      ));
    }
    if (group.directCount > 0) {
      chips.add(_Chip(
        label: 'mkt.inbox.contextDirect'.tr(),
        color: Colors.teal,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 4, runSpacing: 2, children: chips);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.orange.withValues(alpha: .1),
        child: const Icon(
          Icons.person_outline_rounded,
          color: AppColors.orange,
        ),
      );
}

// ---------------------------------------------------------------------------
// Picker sheet — shown when a person has multiple conversations
// ---------------------------------------------------------------------------

class _ConversationPickerSheet extends StatelessWidget {
  final InboxParticipantGroup group;
  final void Function(MarketplaceConversation) onPick;

  const _ConversationPickerSheet({
    required this.group,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.card : AppColors.lightCard;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'mkt.inbox.selectConversation'.tr(),
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(height: 1),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.conversations.length,
              itemBuilder: (_, i) {
                final conv = group.conversations[i];
                final isListing = conv.listingId.isNotEmpty;
                final isReel =
                    conv.reelId.isNotEmpty && conv.listingId.isEmpty;

                final contextLabel = isListing
                    ? 'mkt.inbox.contextListing'.tr()
                    : isReel
                        ? 'mkt.inbox.contextReel'.tr()
                        : 'mkt.inbox.contextDirect'.tr();
                final contextColor = isListing
                    ? AppColors.orange
                    : isReel
                        ? Colors.purple
                        : Colors.teal;
                final title = isListing
                    ? conv.listingTitle
                    : isReel
                        ? conv.reelTitle
                        : group.otherUserName;

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: contextColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isListing
                          ? Icons.shopping_bag_outlined
                          : isReel
                              ? Icons.play_circle_outline_rounded
                              : Icons.person_outline_rounded,
                      color: contextColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    title.isNotEmpty ? title : contextLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    conv.lastMessage.isEmpty
                        ? contextLabel
                        : conv.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  trailing: conv.unreadFor(
                              FirebaseAuth.instance.currentUser?.uid ?? '') >
                          0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conv.unreadFor(FirebaseAuth.instance.currentUser?.uid ?? '')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onPick(conv);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / error state
// ---------------------------------------------------------------------------

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
